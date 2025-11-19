'use client'

import { useState } from 'react'
import { createApplication } from '@/services/api'
import { RxCross2 } from "react-icons/rx";
import { TbLoader2 } from "react-icons/tb";
import type { ApplicationFormData } from '@/types'

interface ApplicationFormProps {
  onClose: () => void
  onSuccess: () => void
}

export default function ApplicationForm({ onClose, onSuccess }: ApplicationFormProps) {
  const [formData, setFormData] = useState<ApplicationFormData>({
    App_name: '',
    Application: '',
    Email: '',
    Domain: ''
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

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

    console.log("[handleSubmit] Form data:", formData);
    try {
      await createApplication(formData)
      onSuccess()
      } catch (error: unknown) {
        if (error instanceof Error) {
          setError(error.message);
        } else {
          setError("Failed to create application");
        }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md animate-slide-up">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">
            Register New Application
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <RxCross2 className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label
              htmlFor="App_name"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Application Name
            </label>
            <input
              id="App_name"
              name="App_name"
              type="text"
              value={formData.App_name}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., CHA - Student Platform"
              required
            />
          </div>

          <div>
            <label
              htmlFor="Application"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Application ID
            </label>
            <input
              id="Application"
              name="Application"
              type="text"
              value={formData.Application}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., App1"
              required
            />
          </div>

          <div>
            <label
              htmlFor="Email"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Email Address
            </label>
            <input
              id="Email"
              name="Email"
              type="email"
              value={formData.Email}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., no-reply@cha.com"
              required
            />
          </div>

          <div>
            <label
              htmlFor="Domain"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Domain
            </label>
            <input
              id="Domain"
              name="Domain"
              type="text"
              value={formData.Domain}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., cha.com"
              required
            />
          </div>

          {error && (
            <div className="bg-danger-50 border border-danger-200 text-danger-600 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1 justify-center p-2 rounded"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="btn-primary flex-1 justify-center p-2 rounded"
            >
              {loading ? (
                <>
                  <TbLoader2 className="w-4 h-4 animate-spin" />
                  Creating...
                </>
              ) : (
                "Create Application"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}