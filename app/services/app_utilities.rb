class AppUtilities
  class << self
    @@app_mode_flags = 0

    # Application Mode Bitwise Flags (Must Be Powers Of 2)
    APP_MODE_AMQP_SENDER = 1
    APP_MODE_AMQP_RECEIVER = 2
    APP_MODE_CIAP = 4
    APP_MODE_ECIS = 8
    APP_MODE_CIR = 16
    APP_MODE_LEGACY_ARCH = 32
    APP_MODE_DMS_1B_ARCH = 64
    APP_MODE_DMS_1C_ARCH = 128
    APP_MODE_TS_ARCH = 256

    # Get the app mode bitwise flags (setting the class variable if unset)
    def get_app_mode
      # Return the app mode bitwise flags if they have already been set.
      return @@app_mode_flags unless @@app_mode_flags == 0
      # Initialize the flags to 0.
      mode_flags = 0
      # Add AMQP-related flags.
      mode_flags += APP_MODE_AMQP_SENDER if Setting.USE_AMQP_SENDER == true
      mode_flags += APP_MODE_AMQP_RECEIVER if Setting.USE_AMQP_RECEIVER == true

      if Setting.MODE == 'CIAP'
        # CIAP or ECIS
        if Setting.HUMAN_REVIEW_ENABLED == true
          if Setting.SANITIZATION_ENABLED == true
            if Setting.DISSEMINATION_LABELING_ENABLED == true
              # CIAP w/ DMS 1c architecture
              mode_flags += APP_MODE_CIAP + APP_MODE_DMS_1C_ARCH
            else
              # CIAP w/ DMS 1b architecture
              mode_flags += APP_MODE_CIAP + APP_MODE_DMS_1B_ARCH
            end
          else # Setting.SANITIZATION_ENABLED == false
            # CIAP w/ legacy architecture
            mode_flags += APP_MODE_CIAP + APP_MODE_LEGACY_ARCH
          end
        else # Setting.HUMAN_REVIEW_ENABLED == false
          if Setting.SANITIZATION_ENABLED == true
            # ECIS w/ legacy architecture
            mode_flags += APP_MODE_ECIS + APP_MODE_LEGACY_ARCH
          else # Setting.SANITIZATION_ENABLED == false
            if Setting.CLASSIFICATION == false
              if Setting.DISSEMINATION_LABELING_ENABLED == false
                # ECIS w/ DMS 1c architecture
                mode_flags += APP_MODE_ECIS + APP_MODE_DMS_1C_ARCH
              else
                # ECIS w/ DMS 1b architecture
                mode_flags += APP_MODE_ECIS + APP_MODE_DMS_1B_ARCH
              end
            else # Setting.CLASSIFICATION == true
              # TS-CIAP
              mode_flags += APP_MODE_CIAP + APP_MODE_TS_ARCH
            end
          end
        end
      elsif Setting.MODE == 'CIR'
        # CIR
        mode_flags += APP_MODE_CIR
      end

      # Assign the app mode flags and return.
      @@app_mode_flags = mode_flags
    end

    def is_ciap?
      get_app_mode & APP_MODE_CIAP == APP_MODE_CIAP
    end

    def is_ecis?
      get_app_mode & APP_MODE_ECIS == APP_MODE_ECIS
    end

    def is_cir?
      get_app_mode & APP_MODE_CIR == APP_MODE_CIR
    end

    def is_legacy_arch?
      get_app_mode & APP_MODE_LEGACY_ARCH == APP_MODE_LEGACY_ARCH
    end

    def is_dms_1b_arch?
      get_app_mode & APP_MODE_DMS_1B_ARCH == APP_MODE_DMS_1B_ARCH
    end

    def is_dms_1c_arch?
      get_app_mode & APP_MODE_DMS_1C_ARCH == APP_MODE_DMS_1C_ARCH
    end

    def is_ts_arch?
      get_app_mode & APP_MODE_TS_ARCH == APP_MODE_TS_ARCH
    end

    def is_ciap_legacy_arch?
      flags = APP_MODE_CIAP + APP_MODE_LEGACY_ARCH
      get_app_mode & flags == flags
    end

    def is_ecis_legacy_arch?
      flags = APP_MODE_ECIS + APP_MODE_LEGACY_ARCH
      get_app_mode & flags == flags
    end

    def is_ciap_dms_1b_arch?
      flags = APP_MODE_CIAP + APP_MODE_DMS_1B_ARCH
      get_app_mode & flags == flags
    end

    def is_ecis_dms_1b_arch?
      flags = APP_MODE_ECIS + APP_MODE_DMS_1B_ARCH
      get_app_mode & flags == flags
    end

    def is_ciap_dms_1c_arch?
      flags = APP_MODE_CIAP + APP_MODE_DMS_1C_ARCH
      get_app_mode & flags == flags
    end

    def is_ecis_dms_1c_arch?
      flags = APP_MODE_ECIS + APP_MODE_DMS_1C_ARCH
      get_app_mode & flags == flags
    end

    def is_ciap_ts_arch?
      flags = APP_MODE_CIAP + APP_MODE_TS_ARCH
      get_app_mode & flags == flags
    end

    def is_ciap_dms_1b_or_1c_arch?
      AppUtilities.is_ciap_dms_1b_arch? || AppUtilities.is_ciap_dms_1c_arch?
    end

    def is_ecis_dms_1b_or_1c_arch?
      AppUtilities.is_ecis_dms_1b_arch? || AppUtilities.is_ecis_dms_1c_arch?
    end

    def is_amqp_sender?
      get_app_mode & APP_MODE_AMQP_SENDER == APP_MODE_AMQP_SENDER
    end

    def is_amqp_receiver?
      get_app_mode & APP_MODE_AMQP_RECEIVER == APP_MODE_AMQP_RECEIVER
    end

    def is_amqp_enabled?
      # Both AMQP sending and receiving enabled.
      flags = APP_MODE_AMQP_SENDER + APP_MODE_AMQP_RECEIVER
      get_app_mode & flags == flags
    end
  end
end
