object @audit

attributes :message,
           :details,
           :audit_type,
           :justification,
           :event_time,
           :system_guid,
           :username,
           :user_guid

child :user do
  attributes :guid,:username,:id
end
