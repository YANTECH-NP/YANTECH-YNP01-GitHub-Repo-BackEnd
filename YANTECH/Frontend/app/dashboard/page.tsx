'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import Header from '@/components/Header'
import ApplicationForm from '@/components/ApplicationForm'
import ApplicationList from '@/components/ApplicationList'
import NotificationForm from "@/components/NotificationForm";
import { getApplications } from "@/services/api";
import { FaPlus, FaBell } from "react-icons/fa";
import { MdManageAccounts } from "react-icons/md";
import type { Application } from "@/types";

export default function DashboardPage() {
  const [applications, setApplications] = useState<Application[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [showNotificationForm, setShowNotificationForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const { isAuthenticated } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login");
      return;
    }
    loadApplications();
  }, [isAuthenticated, router]);

  const loadApplications = async () => {
    try {
      const apps = await getApplications();
      setApplications(apps);
    } catch (error: unknown) {
      console.error("Failed to load applications:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleApplicationCreated = () => {
    setShowForm(false);
    loadApplications();
  };

  const handleNotificationSent = () => {
    setShowNotificationForm(false);
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-gray-600 mt-1">
                Manage your notification applications and send notifications
              </p>
            </div>
            <div className="flex flex-col sm:flex-row gap-3">
              <button
                onClick={() => setShowNotificationForm(true)}
                className="flex gap-2 bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md transition-colors justify-center items-center"
              >
                <FaBell className="w-4 h-4" />
                Send Notification
              </button>
              <button
                onClick={() => setShowForm(true)}
                className="flex gap-2 btn-primary p-2 rounded mx-auto w-[80%] justify-center sm:w-auto "
              >
                <FaPlus className="w-4 h-4 mt-1" />
                Register Application
              </button>
              <button
                onClick={() => router.push('/api_key_management')} 
                className="flex gap-2 btn-secondary p-2 rounded mx-auto w-[80%] justify-center sm:w-auto "
              >
                <MdManageAccounts className="w-4 h-4 mt-1" />
                Manage APIs
              </button>
            </div>
          </div>
        </div>

        {showForm && (
          <ApplicationForm
            onClose={() => setShowForm(false)}
            onSuccess={handleApplicationCreated}
          />
        )}

        {showNotificationForm && (
          <NotificationForm
            onClose={() => setShowNotificationForm(false)}
            onSuccess={handleNotificationSent}
          />
        )}

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : (
          <ApplicationList
            applications={applications}
            onUpdate={loadApplications}
          />
        )}
      </main>
    </div>
  );
}