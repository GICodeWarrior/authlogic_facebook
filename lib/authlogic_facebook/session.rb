module AuthlogicFacebook
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end

    module Config
      # REQUIRED
      #
      # Specify your api_key.
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def facebook_api_key(value=nil)
        rw_config(:facebook_api_key, value, nil)
      end
      alias_method :facebook_api_key=, :facebook_api_key

      # REQUIRED
      #
      # Specify your secret_key.
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def facebook_secret_key(value=nil)
        rw_config(:facebook_secret_key, value, nil)
      end
      alias_method :facebook_secret_key=, :facebook_secret_key

      # What user field should be used for the facebook UID?
      #
      # * <tt>Default:</tt> :facebook_uid
      # * <tt>Accepts:</tt> Symbol
      def facebook_uid_field(value=nil)
        rw_config(:facebook_uid_field, value, :facebook_uid)
      end
      alias_method :facebook_uid_field=, :facebook_uid_field

      # What method should be used to find the facebook account?
      #
      # * <tt>Default:</tt> :find_by_#{facebook_uid_field}
      # * <tt>Accepts:</tt> Symbol or String
      def facebook_finder(value=nil)
        rw_config(:facebook_finder, value, nil)
      end
      alias_method :facebook_finder=, :facebook_finder

      # What extended permissions should be requested from the user?
      #
      # * <tt>Default:</tt> []
      # * <tt>Accepts:</tt> Array of Strings
      def facebook_permissions(value=nil)
        rw_config(:facebook_permissions, value, [])
      end
      alias_method :facebook_permissions=, :facebook_permissions

      # Should a new user be automatically created if there is no user with
      # given facebook uid?
      #
      # * <tt>Default:</tt> false
      # * <tt>Accepts:</tt> Boolean
      def facebook_auto_register(value=true)
        rw_config(:facebook_auto_register, value, false)
      end
      alias_method :facebook_auto_register=, :facebook_auto_register
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_facebook, :if => :authenticating_with_facebook?
        end
      end

      # Clears out the block if we are authenticating with Facebook so that we
      # can redirect without a DoubleRender error.
      def save(&block)
        block = nil if redirecting_to_facebook?
        super(&block)
      end

      protected
      # Override this if you want only some requests to use facebook
      def authenticating_with_facebook?
        !authenticating_with_unauthorized_record? &&
          !self.class.facebook_api_key.blank? &&
          !self.class.facebook_secret_key.blank?
      end

      def redirect_to_facebook
        controller.redirect_to(facebook_login_url)
      end

      private
      def validate_by_facebook
        if facebook_callback?
          facebook_uid = facebook_session['uid']
          self.attempted_record = klass.send(facebook_finder, facebook_uid)

          if self.attempted_record || !facebook_auto_register?
            return !!self.attempted_record
          else
            self.attempted_record = klass.new
            self.attempted_record.send(:"#{facebook_uid_field}=", facebook_uid)
            if self.attempted_record.respond_to?(:before_connect)
              self.attempted_record.send(:before_connect, facebook_session)
            end

            return self.attempted_record.save(false)
          end
        else
          redirect_to_facebook
          return false
        end
      end

      def facebook_session
        return @facebook_session if defined?(@facebook_session)
        session_key = unverified_facebook_params['session_key']

        uid = nil
        10.times do
          params = {'session_key' => session_key}
          begin
            uid = MiniFB.call(self.class.facebook_api_key,
                              self.class.facebook_secret_key,
                              'Users.getLoggedInUser', params)
            break
          rescue Errno::ECONNRESET, EOFError, Timeout::Error => e
            exception = e
          end
        end

        if !uid
          raise exception
        end

        @facebook_session = {'uid' => uid, 'session_key' => session_key}
      end

      def unverified_facebook_params
        if defined?(@unverified_facebook_params)
          return @unverified_facebook_params
        end

        begin
          params = JSON.parse(controller.params['session'] || '')
        rescue JSON::JSONError
          params = {}
        end

        @unverified_facebook_params = params.is_a?(Hash) ? params : {}
      end

      def facebook_auto_register?
        self.class.facebook_auto_register
      end

      def facebook_callback?
        !unverified_facebook_params['uid'].blank?
      end

      def redirecting_to_facebook?
        authenticating_with_facebook? && !facebook_callback?
      end

      def facebook_uid_field
        self.class.facebook_uid_field
      end

      def facebook_finder
        self.class.facebook_finder || "find_by_#{facebook_uid_field}"
      end

      def facebook_login_params
        {'api_key' => self.class.facebook_api_key,
         'req_perms' => self.class.facebook_permissions.join(','),
         'next' => controller.request.url,
         'v' => '1.0',
         'connect_display' => 'popup',
         'fbconnect' => 'true',
         'return_session' => 'true'}
      end

      def facebook_login_url
        params = facebook_login_params.map do |key, value|
          "#{CGI.escape(key)}=#{CGI.escape(value)}"
        end

        "http://www.facebook.com/login.php?#{params.join('&')}"
      end
    end
  end
end
