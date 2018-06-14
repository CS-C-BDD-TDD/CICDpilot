class AvpMessage < ActiveRecord::Base

  self.table_name = 'avp_messages'
  has_one :uploaded_file, primary_key: :id, foreign_key: :avp_message_id
  belongs_to :user, foreign_key: :user_guid, primary_key: :guid

  include Guidable

  def self.send_to_avp(data,*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    url = Setting.FLARE_AVP_PATH
    post_opts = opts
    avp_message = nil

    begin
      AvpValidationLogger.info("[AVP][send_data] Starting AVP Validation to #{url} ...")
      uri = URI.parse(url)
      request_uri = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      post = Net::HTTP::Post.new(request_uri)
      content_type = post_opts.delete('Content-type') || post_opts.delete('Content-Type') || 'application/json'
      post["Content-type"] = content_type
      post_opts.each_pair do |key,value|
        post[key] = value
      end
      post.body = data
      AvpValidationLogger.debug("[AVP][send_data] request body: #{post.body}")
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_PEER) do |https|
        https.request(post)
      end

      if response.present?
        avp_response = ActiveSupport::JSON.decode(response.body)

        avp_errors = avp_response["errors"].present? ? avp_response["errors"].map(&:inspect).join(",") : nil
        prohibited = avp_response["prohibited"].present? ? avp_response["prohibited"].map(&:inspect).join(",") : nil
        avp_valid = (avp_response["errors"].present? && avp_response["errors"].length == 0) || avp_response["errors"].blank?

        avp_message = AvpMessage.create(:avp_errors => avp_errors, :prohibited => prohibited, :timestamp => avp_response["timestamp"], :avp_valid => avp_valid)
      end

      AvpValidationLogger.info("[AVP][send_data]response.code: #{response.code}, response.body: #{response.body}")
      return avp_message
    rescue Exception => e
      AvpValidationLogger.info("[AVP][send_data] failed due to an internal error.  Please check the exceptions log.")
      ExceptionLogger.debug("exception: #{e},message: #{e.message},backtrace: #{e.backtrace}")
      if response.present?
        {errors: ["AVP Returned with Error Code: #{response.code}"]}
      else
        {errors: ["Failed to connect to AVP."]}
      end
    end
  end

private
  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    text :prohibited
    text :avp_errors
    text :guid, as: :text_exact

    #Configure for Sunspot, but don't build indices for searching.  Needed for sorting while searching
    time :created_at, stored: false
    time :updated_at, stored: false
    time :timestamp, stored: false
  end
end
