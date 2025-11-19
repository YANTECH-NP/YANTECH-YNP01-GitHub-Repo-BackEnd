'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import Header from '@/components/Header'
import { getApplications } from '@/services/api'
import { FaArrowLeft, FaBell } from "react-icons/fa";
import { IoMailSharp } from "react-icons/io5";
import { LuMessageSquare } from "react-icons/lu";
import type { Application, Notification } from '@/types'
// import { once } from 'events'

export default function ApplicationDetailPage() {
  const params = useParams()
  const router = useRouter()
  const { isAuthenticated } = useAuth()
  const [application, setApplication] = useState<Application | null>(null)
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)


  

    useEffect(() => {
      if (!isAuthenticated) {
        router.push("/login");
        return;
      }
      const loadApplicationDetail = async () => {
        try {
          const apps = await getApplications();
          const app = apps.find(
            (a: Application) => a.Application === params.id
          );
          setApplication(app || null);

          // Mock notification data - replace with real API call
          setNotifications([
            {
              Application: "1",
              OutputType: "EMAIL",
              Recipient: "user@example.com",
              Subject: "Welcome Email",
              Message: "Welcome to our platform!",
              Interval: {once: true},
            },
            {
              Application: "2",
              Subject: "Verification Code",
              OutputType: "SMS",
              Recipient: "+1234567890",
              Message: "Your verification code is 123456",
              Interval: {daily: true},
            },
            {
              Application: "3",
              OutputType: "PUSH",
              Recipient: "device_token_123",
              Subject: "New Update Available",
              Message: "A new version of the app is available",
              Interval: {weekly: true},
            },
          ]);
        } catch (error) {
          console.error("Failed to load application:", error);
        } finally {
          setLoading(false);
        }
      };
      loadApplicationDetail();
    }, [isAuthenticated, params.id, router ]);

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'EMAIL': return <IoMailSharp className="w-5 h-5" />;
      case 'SMS': return <LuMessageSquare className="w-5 h-5" />;
      case 'PUSH': return <FaBell className="w-5 h-5" />
      default: return <FaBell className="w-5 h-5" />
    }
  }

  const getStatusClass = (status: string) => {
    switch (status) {
      case 'sent': return 'status-badge status-sent'
      case 'pending': return 'status-badge status-pending'
      case 'failed': return 'status-badge status-failed'
      default: return 'status-badge bg-gray-100 text-gray-600'
    }
  }

  if (!isAuthenticated) {
    return null
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Header />
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      </div>
    )
  }

  if (!application) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Header />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900">
              Application Not Found
            </h1>
            <button
              onClick={() => router.push("/dashboard")}
              className="btn-primary mt-4"
            >
              <FaArrowLeft className="w-4 h-4" />
              Back to Dashboard
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <button
            onClick={() => router.push("/dashboard")}
            className="btn-secondary mb-4"
          >
            <FaArrowLeft className="w-4 h-4" />
            Back to Dashboard
          </button>

          <div className="flex items-center gap-4">
            <h1 className="text-3xl font-bold text-gray-900">
              {application.App_name}
            </h1>
            <span className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm font-medium">
              {application.Application}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Application Info */}
          <div className="lg:col-span-1">
            <div className="card">
              <h2 className="text-xl font-semibold text-gray-900 mb-6">
                Application Details
              </h2>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">
                    Application ID
                  </label>
                  <p className="text-gray-900 font-mono text-sm">
                    {application.Application}
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">
                    Email
                  </label>
                  <p className="text-gray-900">{application.Email}</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-500 mb-1">
                    Domain
                  </label>
                  <p className="text-gray-900">{application.Domain}</p>
                </div>

                {application["SES-Domain-ARN"] && (
                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">
                      SES Domain ARN
                    </label>
                    <p className="text-gray-900 font-mono text-xs break-all">
                      {application["SES-Domain-ARN"]}
                    </p>
                  </div>
                )}

                {application["SNS-Topic-ARN"] && (
                  <div>
                    <label className="block text-sm font-medium text-gray-500 mb-1">
                      SNS Topic ARN
                    </label>
                    <p className="text-gray-900 font-mono text-xs break-all">
                      {application["SNS-Topic-ARN"]}
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Notifications */}
          <div className="lg:col-span-2">
            <div className="card">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-semibold text-gray-900">
                  Notification History
                </h2>
                <span className="text-sm text-gray-500">
                  {notifications.length} total
                </span>
              </div>

              {notifications.length === 0 ? (
                <div className="text-center py-12">
                  <FaBell className="w-12 h-12 text-gray-300 mx-auto mb-4" />
                  <p className="text-gray-500">No notifications sent yet</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {notifications.map((notification) => (
                    <div
                      key={notification.Application}
                      className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <div className="p-2 bg-gray-100 rounded-lg">
                            {getTypeIcon(notification.OutputType)}
                          </div>
                          <div>
                            <h3 className="font-medium text-gray-900">
                              {notification.OutputType}
                            </h3>
                            {/* <p className="text-sm text-gray-500">
                              {new Date(
                                notification.Interval
                              ).toLocaleString()}
                            </p> */}
                          </div>
                        </div>
                        {/* <span className={getStatusClass(notification.status)}>
                          {notification.status}
                        </span> */}
                      </div>

                      <div className="space-y-2 text-sm">
                        <div>
                          <span className="font-medium text-gray-700">
                            Recipient:
                          </span>
                          <span className="ml-2 text-gray-900">
                            {notification.Recipient}
                          </span>
                        </div>

                        {notification.Subject && (
                          <div>
                            <span className="font-medium text-gray-700">
                              Subject:
                            </span>
                            <span className="ml-2 text-gray-900">
                              {notification.Subject}
                            </span>
                          </div>
                        )}

                        <div>
                          <span className="font-medium text-gray-700">
                            Message:
                          </span>
                          <span className="ml-2 text-gray-900">
                            {notification.Message}
                          </span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}