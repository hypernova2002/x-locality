# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class BulkTranslateCandidates < Action
                before :require_project_admin!

                def handle(request, response)
                  locale = project(request).locales_dataset.first(public_id: request.params[:id])
                  unless locale
                    return render_problem(response, status: 404, title: 'Not Found',
                                                    detail: 'Locale not found')
                  end

                  data = Backend::Locales::BulkTranslateCandidates.new.call(project: project(request),
                                                                            locale: locale).value!

                  response.format = :json
                  response.body = data.to_json
                end
              end
            end
          end
        end
      end
    end
  end
end
