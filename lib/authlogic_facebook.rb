require 'authlogic_facebook/acts_as_authentic'
require 'authlogic_facebook/session'
require 'authlogic_facebook/helper'

if ActiveRecord::Base.respond_to?(:add_acts_as_authentic_module)
  ActiveRecord::Base.send(:include, AuthlogicFacebook::ActsAsAuthentic)
  Authlogic::Session::Base.send(:include, AuthlogicFacebook::Session)
  ActionController::Base.helper AuthlogicFacebook::Helper
end
