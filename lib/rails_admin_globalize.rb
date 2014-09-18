require "rails_admin_globalize/engine"

module RailsAdminGlobalize
end

require 'rails_admin/config/actions'

module RailsAdmin
  module Config
    module Actions

      class Globalize < Base

        RailsAdmin::Config::Actions.register(self)

        register_instance_option :pjax? do
          false
        end

        register_instance_option :member? do
          true
        end

        register_instance_option :visible? do
          authorized? && bindings[:object].class.respond_to?("translated_attribute_names")
        end

        register_instance_option :link_icon do
          'icon-globe'
        end

        register_instance_option :member? do
          true
        end

        register_instance_option :http_methods do
          [:get, :put, :patch]
        end

        register_instance_option :controller do

          Proc.new do
            @available_locales =
              if current_user && current_user.respond_to?(:role?) && current_user.role?(:translator) && current_user.respond_to?(:translatable_locales)
                (current_user.translatable_locales || '').split(',') - [I18n.locale.to_s]
              else
                (I18n.available_locales - [I18n.locale]).map(&:to_s)
              end
            @available_locales = @object.available_locales if @object.respond_to?("available_locales")

            @already_translated_locales = []
            @already_translated_locales = @object.translated_locales.map(&:to_s) if @object.respond_to?("translated_locales")

            @not_yet_translated_locales = @available_locales - @already_translated_locales

            @target_locale = params[:target_locale] || @available_locales.first || I18n.locale

            unless request.get?
              if !@available_locales.include? params[:target_locale]
                flash[:error] = I18n.t("rails_admin.globalize.not_allowed")
                redirect_to back_or_index
              else
                result = I18n.with_locale params[:target_locale] do
                  p = params[@abstract_model.param_key]
                  p = p.permit! if @object.class.include?(ActiveModel::ForbiddenAttributesProtection) rescue nil
                  @object.update_attributes(p)
                end

                if result
                  flash[:success] = I18n.t("rails_admin.globalize.success")
                  redirect_to back_or_index
                else
                  flash[:error] = I18n.t("rails_admin.globalize.error")
                end
              end
            end
            @object.inspect
          end

        end

      end
    end
  end
end
