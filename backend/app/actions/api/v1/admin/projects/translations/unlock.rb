# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Unlock < Action
                def handle(request, response)
                  result = Backend::Translations::SetLocked.new.call(
                    project: project(request), key: request.params[:key], locked: false
                  )

                  case result
                  in Success(key)
                    response.format = :json
                    response.body = { key: key, locked: false }.to_json
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
end
