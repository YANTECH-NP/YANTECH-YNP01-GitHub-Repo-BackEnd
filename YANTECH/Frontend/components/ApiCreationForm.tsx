'use client'

import { useState } from 'react'
import { createApiKey } from '@/services/api'
import { RxCross2 } from "react-icons/rx";
import { TbLoader2 } from "react-icons/tb";
import type { ApiCreationFormData } from '@/types'

interface ApiCreationFormProps {
  onClose: () => void
  onSuccess: () => void
}

export default function ApiCreationForm({ onClose, onSuccess }: ApiCreationFormProps) {
  const [formData, setFormData] = useState<ApiCreationFormData>({
    Api_name: '',
    Api_id: ''
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
      await createApiKey(formData)
      onSuccess()
      } catch (error: unknown) {
        if (error instanceof Error) {
          setError(error.message);
        } else {
          setError("Failed to generate API Key");
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
              htmlFor="Api_name"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Api Name
            </label>
            <input
              id="Api_name"
              name="Api_name"
              type="text"
              value={formData.Api_name}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., Third Party Integration"
              required
            />
          </div>

          <div>
            <label
              htmlFor="Api_id"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Api ID
            </label>
            <input
              id="Api_id"
              name="Api_id"
              type="text"
              value={formData.Api_id}
              onChange={handleChange}
              className="input-field"
              placeholder="e.g., key_1l2m3n4o5p"
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
                  Generating...
                </>
              ) : (
                "Generate New Api Key"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}