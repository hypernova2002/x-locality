# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class Delete < Action
                def handle(request, response)
                  locale = project(request).locales_dataset.first(public_id: request.params[:id])
                  unless locale
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Locale not found')
                  end

                  result = Backend::Locales::Delete.new.call(locale: locale)

                  case result
                  in Success(_locale)
                    response.status = 204
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
