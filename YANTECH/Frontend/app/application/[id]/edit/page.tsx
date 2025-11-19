'use client'

import { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import Header from '@/components/Header'
import { getApplications, updateApplication } from '@/services/api'
import { FaArrowLeft } from "react-icons/fa"
import type { Application, ApplicationFormData } from '@/types'

export default function EditApplicationPage() {
  const params = useParams()
  const router = useRouter()
  const { isAuthenticated } = useAuth()
  const [application, setApplication] = useState<Application | null>(null)
  const [formData, setFormData] = useState<ApplicationFormData>({
    App_name: '',
    Application: '',
    Email: '',
    Domain: ''
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const loadApplication = useCallback(async () => {
    try {
      const apps = await getApplications();
      const app = apps.find((a: Application) => a.Application === params.id);
      if (app) {
        setApplication(app);
        setFormData({
          App_name: app.App_name,
          Application: app.Application,
          Email: app.Email,
          Domain: app.Domain,
        });
      }
    } catch (error) {
      console.error("Failed to load application:", error);
    }
  }, [params.id]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login");
      return;
    }
    loadApplication();
  }, [isAuthenticated, router, loadApplication]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      await updateApplication(params.id as string, formData)
      router.push('/dashboard')
    } catch (error: unknown) {
      if (error instanceof Error) {
        setError(error.message)
      } else {
        setError("Failed to update application")
      }
    } finally {
      setLoading(false)
    }
  }

  if (!isAuthenticated || !application) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <main className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <button
          onClick={() => router.push('/dashboard')}
          className="btn-secondary mb-6"
        >
          <FaArrowLeft className="w-4 h-4" />
          Back to Dashboard
        </button>

        <div className="card">
          <h1 className="text-2xl font-bold text-gray-900 mb-6">
            Edit Application
          </h1>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Application Name
              </label>
              <input
                type="text"
                name="App_name"
                value={formData.App_name}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Application ID
              </label>
              <input
                type="text"
                name="Application"
                value={formData.Application}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                required
                disabled
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email
              </label>
              <input
                type="email"
                name="Email"
                value={formData.Email}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Domain
              </label>
              <input
                type="text"
                name="Domain"
                value={formData.Domain}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
                required
              />
            </div>

            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={() => router.push('/dashboard')}
                className="btn-secondary flex-1 justify-center p-2 rounded"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={loading}
                className="btn-primary flex-1 justify-center p-2 rounded"
              >
                {loading ? "Updating..." : "Update Application"}
              </button>
            </div>
          </form>
        </div>
      </main>
    </div>
  )
}