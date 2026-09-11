#include "kstorebackend.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>
#include <QProcess>
#include <QDebug>

namespace {
// Flathub only lets a handful of top-level categories through its
// AppStream data, so map our sidebar entries onto search terms it
// actually understands well.
QString categoryToSearchTerm(const QString &category)
{
    if (category.compare("productivity", Qt::CaseInsensitive) == 0) return "office productivity";
    if (category.compare("development", Qt::CaseInsensitive) == 0) return "developer tools";
    if (category.compare("multimedia", Qt::CaseInsensitive) == 0) return "audio video";
    if (category.compare("games", Qt::CaseInsensitive) == 0) return "games";
    return category;
}
}

KStoreBackend::KStoreBackend(QObject *parent)
    : QObject(parent), m_network(new QNetworkAccessManager(this))
{
    updateInstalledApps();
}

QVariantList KStoreBackend::apps() const
{
    return m_apps;
}

void KStoreBackend::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

// ---------------------------------------------------------------------------
// Browsing — everything here just talks to flathub.org/api/v2
// ---------------------------------------------------------------------------

void KStoreBackend::fetchApps(const QString &category)
{
    setLoading(true);
    m_apps.clear();
    m_allApps.clear();
    m_pendingAppstreamRequests = 0;
    emit appsChanged();

    if (category.compare("installed", Qt::CaseInsensitive) == 0) {
        updateInstalledApps();
        if (m_installedApps.isEmpty()) {
            setLoading(false);
            return;
        }
        for (const QString &id : std::as_const(m_installedApps)) {
            fetchAppstream(id);
        }
        return;
    }

    if (category.compare("discover", Qt::CaseInsensitive) == 0) {
        QNetworkRequest request(QUrl("https://flathub.org/api/v2/collection/recently-added/24"));
        QNetworkReply *reply = m_network->get(request);
        connect(reply, &QNetworkReply::finished, this, &KStoreBackend::onIdListReplyFinished);
        return;
    }

    searchApps(categoryToSearchTerm(category));
}

void KStoreBackend::searchApps(const QString &query)
{
    QNetworkRequest request(QUrl("https://flathub.org/api/v2/search"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject body;
    body["query"] = query;
    body["filters"] = QJsonArray();

    QNetworkReply *reply = m_network->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, &KStoreBackend::onIdListReplyFinished);
}

// Handles both /collection/... and /search responses — both ultimately just
// give us a list of app ids, which we then resolve individually so we get
// consistent, fully-populated fields regardless of which endpoint answered.
void KStoreBackend::onIdListReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply) return;

    QStringList ids;
    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray hits;
        if (doc.isArray()) {
            hits = doc.array();
        } else if (doc.isObject()) {
            const QJsonObject root = doc.object();
            if (root.contains("hits"))
                hits = root.value("hits").toArray();
            else if (root.contains("children"))
                hits = root.value("children").toArray();
        }

        for (const QJsonValue &v : std::as_const(hits)) {
            if (v.isString()) {
                ids << v.toString();
            } else if (v.isObject()) {
                const QJsonObject o = v.toObject();
                QString id = o.value("app_id").toString();
                if (id.isEmpty()) id = o.value("id").toString();
                if (!id.isEmpty()) ids << id;
            }
        }
    } else {
        qWarning() << "Flathub request failed:" << reply->errorString();
    }
    reply->deleteLater();

    if (ids.isEmpty()) {
        setLoading(false);
        return;
    }

    static constexpr int kMaxResults = 24;
    for (const QString &id : ids.mid(0, kMaxResults)) {
        fetchAppstream(id);
    }
}

void KStoreBackend::fetchAppstream(const QString &appId)
{
    QNetworkRequest request(QUrl("https://flathub.org/api/v2/appstream/" + appId));
    QNetworkReply *reply = m_network->get(request);
    reply->setProperty("appId", appId);
    m_pendingAppstreamRequests++;
    connect(reply, &QNetworkReply::finished, this, &KStoreBackend::onAppstreamReplyFinished);
}

void KStoreBackend::onAppstreamReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply *>(sender());
    if (!reply) return;

    m_pendingAppstreamRequests = qMax(0, m_pendingAppstreamRequests - 1);
    const QString appId = reply->property("appId").toString();

    if (reply->error() == QNetworkReply::NoError) {
        const QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();
        if (!obj.isEmpty()) {
            const QJsonArray cats = obj.value("categories").toArray();

            QVariantMap app;
            app["name"]      = obj.value("name").toString(appId);
            app["packageId"] = appId;
            app["icon"]      = obj.value("icon").toString();
            app["category"]  = cats.isEmpty() ? QStringLiteral("App") : cats.first().toString();

            bool alreadyListed = false;
            for (const QVariant &existing : std::as_const(m_allApps)) {
                if (existing.toMap().value("packageId").toString() == appId) {
                    alreadyListed = true;
                    break;
                }
            }
            if (!alreadyListed) {
                m_allApps.append(app);
                m_apps.append(app);
                emit appsChanged();
            }
        }
    } else {
        qWarning() << "Failed to fetch appstream for" << appId << ":" << reply->errorString();
    }
    reply->deleteLater();

    if (m_pendingAppstreamRequests == 0) {
        setLoading(false);
    }
}

// Client-side filter over the currently loaded category so typing in the
// search box doesn't hammer the Flathub API on every keystroke.
void KStoreBackend::filterApps(const QString &text)
{
    if (text.trimmed().isEmpty()) {
        m_apps = m_allApps;
        emit appsChanged();
        return;
    }

    QVariantList filtered;
    for (const QVariant &v : std::as_const(m_allApps)) {
        const QVariantMap app = v.toMap();
        if (app.value("name").toString().contains(text, Qt::CaseInsensitive)) {
            filtered.append(app);
        }
    }
    m_apps = filtered;
    emit appsChanged();
}

// ---------------------------------------------------------------------------
// Installed-app bookkeeping — straight from `flatpak list`
// ---------------------------------------------------------------------------

void KStoreBackend::updateInstalledApps()
{
    QProcess proc;
    proc.start("flatpak", {"list", "--app", "--columns=application"});
    if (!proc.waitForFinished(5000)) {
        qWarning() << "flatpak list timed out";
        return;
    }

    const QString output = QString::fromUtf8(proc.readAllStandardOutput());
    QStringList ids = output.split('\n', Qt::SkipEmptyParts);
    for (QString &id : ids) id = id.trimmed();

    m_installedApps = ids;
    emit installedAppsChanged();
}

// ---------------------------------------------------------------------------
// Install / uninstall / launch — all just `flatpak ...`
// ---------------------------------------------------------------------------

void KStoreBackend::setAppProgress(const QString &packageId, double progress, const QString &status)
{
    QVariantMap data;
    data["progress"]   = progress;
    data["status"]     = status;
    data["installing"] = (progress < 1.0 && progress >= 0);
    m_installationProgress[packageId] = data;
    emit installationProgressChanged();
}

void KStoreBackend::installApp(const QString &packageId, const QString &appName, const QString &iconUrl)
{
    Q_UNUSED(iconUrl);

    setAppProgress(packageId, 0.05, "Starting install...");
    emit installationStarted(packageId);

    auto *proc = new QProcess(this);
    proc->setProcessChannelMode(QProcess::SeparateChannels);

    connect(proc, &QProcess::readyReadStandardOutput, this, [this, proc, packageId]() {
        const QString chunk = QString::fromUtf8(proc->readAllStandardOutput());

        static const QRegularExpression pctRe("(\\d{1,3})\\s*%");
        const QRegularExpressionMatch match = pctRe.match(chunk);

        if (match.hasMatch()) {
            const double pct = match.captured(1).toDouble() / 100.0;
            setAppProgress(packageId, qBound(0.0, pct, 0.99), QString("Installing... %1%").arg(match.captured(1)));
        } else if (chunk.contains("Downloading", Qt::CaseInsensitive)) {
            setAppProgress(packageId, 0.3, "Downloading...");
        } else if (chunk.contains("Installing", Qt::CaseInsensitive)) {
            setAppProgress(packageId, 0.7, "Installing...");
        }
    });

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc, packageId, appName](int exitCode, QProcess::ExitStatus exitStatus) {
        const bool success = (exitStatus == QProcess::NormalExit && exitCode == 0);

        if (success) {
            setAppProgress(packageId, 1.0, "Installed");
            updateInstalledApps();
            emit installationFinished(packageId, true, "Installed " + appName);
        } else {
            const QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
            setAppProgress(packageId, -1.0, "Install failed");
            emit installationFinished(packageId, false, "Install failed: " + (err.isEmpty() ? "unknown error" : err));
        }
        proc->deleteLater();
    });

    proc->start("flatpak", {"install", "-y", "--noninteractive", "flathub", packageId});
}

void KStoreBackend::uninstallApp(const QString &packageId)
{
    auto *proc = new QProcess(this);
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, proc, packageId](int exitCode, QProcess::ExitStatus exitStatus) {
        const bool success = (exitStatus == QProcess::NormalExit && exitCode == 0);
        if (success) {
            updateInstalledApps();
            emit installationFinished(packageId, true, "Uninstalled " + packageId);
        } else {
            const QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
            emit installationFinished(packageId, false, "Uninstall failed: " + (err.isEmpty() ? "unknown error" : err));
        }
        proc->deleteLater();
    });
    proc->start("flatpak", {"uninstall", "-y", "--noninteractive", packageId});
}

void KStoreBackend::openApp(const QString &packageId)
{
    QProcess::startDetached("flatpak", {"run", packageId});
}
