# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Account
            # Any account member can change these - they're display/branding
            # preferences, not a security boundary like the owner-only
            # actions elsewhere in this namespace.
            class Update < Admin::Action
              params do
                optional(:name).filled(:string)
                optional(:timezone).filled(:string)
                optional(:logo_url).maybe(:string)
                optional(:correspondence_name).maybe(:string)
              end

              def handle(request, response)
                unless request.params.valid?
                  return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                  errors: request.params.errors.to_h)
                end

                updates = request.params.to_h.slice(:name, :timezone, :logo_url, :correspondence_name)
                result = Backend::Accounts::Update.new.call(account: current_user(request).account, updates: updates)

                case result
                in Success(account)
                  response.format = :json
                  response.body = Backend::Serializers::AccountSerializer.new(account).serialize
                in Failure[code, detail]
                  render_failure(response, code, detail)
                end
              end
            end
          end
        end
      end
    end
  end
end
