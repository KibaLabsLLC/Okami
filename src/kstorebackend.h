#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QStringList>

class QNetworkAccessManager;
class QNetworkReply;

class KStoreBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList apps READ apps NOTIFY appsChanged)
    Q_PROPERTY(bool loading READ loading WRITE setLoading NOTIFY loadingChanged)
    Q_PROPERTY(QStringList installedApps READ installedApps NOTIFY installedAppsChanged)
    Q_PROPERTY(QVariantMap installationProgress READ installationProgress NOTIFY installationProgressChanged)

public:
    explicit KStoreBackend(QObject *parent = nullptr);

    QVariantList apps() const;
    bool loading() const { return m_loading; }
    void setLoading(bool loading);
    QStringList installedApps() const { return m_installedApps; }
    QVariantMap installationProgress() const { return m_installationProgress; }

public slots:
    // category is one of: discover, productivity, development, multimedia,
    // games, installed — or any free-text search term
    void fetchApps(const QString &category);
    void filterApps(const QString &text);

    void installApp(const QString &packageId, const QString &appName, const QString &iconUrl);
    void uninstallApp(const QString &packageId);
    void openApp(const QString &packageId);
    void updateInstalledApps();

signals:
    void appsChanged();
    void loadingChanged();
    void installedAppsChanged();
    void installationProgressChanged();
    void installationStarted(const QString &packageId);
    void installationFinished(const QString &packageId, bool success, const QString &message);

private slots:
    void onIdListReplyFinished();
    void onAppstreamReplyFinished();

private:
    void searchApps(const QString &query);
    void fetchAppstream(const QString &appId);
    void setAppProgress(const QString &packageId, double progress, const QString &status);

    QNetworkAccessManager *m_network;

    QVariantList m_apps;     // apps currently shown (post client-side filter)
    QVariantList m_allApps;  // full unfiltered result of the last fetchApps()
    bool m_loading = false;

    QStringList m_installedApps;
    QVariantMap m_installationProgress;

    int m_pendingAppstreamRequests = 0;
};
