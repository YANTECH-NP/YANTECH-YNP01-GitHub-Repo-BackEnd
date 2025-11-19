'use client'

import { useState, useEffect } from 'react'
import { requestNotification, getApplications } from '@/services/api'
import { RxCross2 } from "react-icons/rx";
import { TbLoader2 } from "react-icons/tb";
import type { NotificationRequest, Application } from '@/types'

interface NotificationFormProps {
  onClose: () => void
  onSuccess: () => void
}

export default function NotificationForm({ onClose, onSuccess }: NotificationFormProps) {
  const [applications, setApplications] = useState<Application[]>([])
  const [formData, setFormData] = useState<NotificationRequest>({
    Application: "",
    Recipient: "",
    Subject: "",
    Message: "",
    OutputType: "EMAIL",
    PhoneNumber: "",
    Interval: {
      Days: [],
    },
    EmailAddresses: [""],
  });
  const [intervalType, setIntervalType] = useState<string>("Once");
  const [customDays, setCustomDays] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    loadApplications();
  }, []);

  const loadApplications = async () => {
    try {
      const apps = await getApplications();
      setApplications(apps);
    } catch (error) {
      console.error("Failed to load applications:", error);
    }
  };

  const handleChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement
    >
  ) => {
    const { name, value } = e.target;

    if (name === "EmailAddresses") {
      setFormData({
        ...formData,
        [name]: value.split(",").map((email) => email.trim()),
      });
    } else if (name === "customDays") {
      setCustomDays(value);
    } else {
      setFormData({
        ...formData,
        [name]: value,
      });
    }
  };

  const handleIntervalChange = (intervalType: string) => {
    setIntervalType(intervalType);
    if (intervalType === "Custom") {
      // Don't update formData yet, wait for custom days input
      return;
    }
    setFormData({
      ...formData,
      Interval: {
        [intervalType]: true,
      },
    });
  };

  const handleCustomDaysSubmit = () => {
    if (customDays) {
      const daysArray = customDays
        .split(",")
        .map((day) => parseInt(day.trim()))
        .filter((day) => !isNaN(day));
      setFormData({
        ...formData,
        Interval: {
          Days: daysArray,
        },
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");

    // Update recipient to match first email address if using EMAIL
    const notificationData = {
      ...formData,
      Recipient:
        formData.OutputType === "EMAIL"
          ? formData.EmailAddresses?.[0] || ""
          : formData.Recipient,
      // Set default EmailAddresses for SMS to avoid empty array
      EmailAddresses:
        formData.OutputType === "SMS"
          ? ["noreply@example.com"] // Default email for SMS
          : formData.EmailAddresses,
    };

    console.log("[handleSubmit] Notification data:", notificationData);

    try {
      await requestNotification(notificationData);
      setSuccess("Notification request sent successfully!");
      setTimeout(() => {
        onSuccess();
      }, 2000);
    } catch (error: unknown) {
      if (error instanceof Error) {
        setError(error.message);
      } else {
        setError("Failed to send notification request");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">
            Send Notification
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <RxCross2 className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
              {error}
            </div>
          )}

          {success && (
            <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
              {success}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label
                htmlFor="Application"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Application *
              </label>
              <select
                id="Application"
                name="Application"
                value={formData.Application}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              >
                <option value="">Select Application</option>
                {applications.map((app) => (
                  <option key={app.Application} value={app.Application}>
                    {app.App_name} ({app.Application})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor="OutputType"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Output Type *
              </label>
              <select
                id="OutputType"
                name="OutputType"
                value={formData.OutputType}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              >
                <option value="EMAIL">Email</option>
                <option value="SMS">SMS</option>
                <option value="PUSH">Push Notification</option>
              </select>
            </div>
          </div>

          <div>
            <label
              htmlFor="Subject"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Subject *
            </label>
            <input
              type="text"
              id="Subject"
              name="Subject"
              value={formData.Subject}
              onChange={handleChange}
              required
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              placeholder="Enter notification subject"
            />
          </div>

          <div>
            <label
              htmlFor="Message"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Message *
            </label>
            <textarea
              id="Message"
              name="Message"
              value={formData.Message}
              onChange={handleChange}
              required
              rows={4}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              placeholder="Enter your message"
            />
          </div>

          {formData.OutputType === "EMAIL" && (
            <div>
              <label
                htmlFor="EmailAddresses"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Email Addresses *
              </label>
              <input
                type="text"
                id="EmailAddresses"
                name="EmailAddresses"
                value={formData.EmailAddresses?.join(", ") || ""}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="Enter email addresses separated by commas"
              />
              <p className="text-sm text-gray-500 mt-1">
                Separate multiple email addresses with commas
              </p>
            </div>
          )}

          {formData.OutputType === "SMS" && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label
                  htmlFor="Recipient"
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Recipient *
                </label>
                <input
                  type="text"
                  id="Recipient"
                  name="Recipient"
                  value={formData.Recipient}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  placeholder="Enter recipient identifier"
                />
              </div>
              <div>
                <label
                  htmlFor="PhoneNumber"
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Phone Number *
                </label>
                <input
                  type="tel"
                  id="PhoneNumber"
                  name="PhoneNumber"
                  value={formData.PhoneNumber || ""}
                  onChange={handleChange}
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  placeholder="+15555555555"
                />
              </div>
            </div>
          )}

          {formData.OutputType === "PUSH" && (
            <div>
              <label
                htmlFor="Recipient"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Recipient *
              </label>
              <input
                type="text"
                id="Recipient"
                name="Recipient"
                value={formData.Recipient}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                placeholder="Enter recipient identifier"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Delivery Schedule *
            </label>
            <div className="flex flex-wrap gap-4">
              {["Once", "Daily", "Weekly", "Monthly", "Custom"].map(
                (interval) => (
                  <label key={interval} className="flex items-center">
                    <input
                      type="radio"
                      name="interval"
                      value={interval}
                      checked={
                        interval === "Custom"
                          ? intervalType === "Custom" ||
                            !!formData.Interval.Days
                          : formData.Interval[
                              interval as keyof typeof formData.Interval
                            ] === true
                      }
                      onChange={() => handleIntervalChange(interval)}
                      className="mr-2"
                    />
                    {interval}
                  </label>
                )
              )}
            </div>

            {(intervalType === "Custom" || formData.Interval.Days) && (
              <div className="mt-4">
                <label
                  htmlFor="customDays"
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Custom Days (comma-separated numbers) *
                </label>
                <input
                  type="text"
                  id="customDays"
                  name="customDays"
                  value={
                    customDays ||
                    (formData.Interval.Days
                      ? formData.Interval.Days.join(", ")
                      : "")
                  }
                  onChange={handleChange}
                  onBlur={handleCustomDaysSubmit}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  placeholder="e.g., 1, 15, 30"
                />
                <p className="text-sm text-gray-500 mt-1">
                  Enter specific days of the month (1-31)
                </p>
              </div>
            )}
          </div>

          <div className="flex justify-end space-x-4 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              {loading && <TbLoader2 className="w-4 h-4 animate-spin" />}
              {loading ? "Sending..." : "Send Notification"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
