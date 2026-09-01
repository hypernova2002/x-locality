# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Translations
              class Export < Action
                params do
                  required(:project_id).filled(:string)
                  optional(:format).filled(:string, included_in?: %w[csv json])
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  format = request.params[:format] || 'csv'
                  result = Backend::Translations::Export.new.call(project: project(request), format: format).value!

                  # Deliberately generic, not application/gzip - some
                  # browsers "helpfully" auto-decompress a gzip-typed
                  # download (especially when the inner extension looks
                  # like a spreadsheet/document type), leaving a
                  # already-decompressed file still named *.gz.
                  response.headers['Content-Type'] = 'application/octet-stream'
                  response.headers['Content-Disposition'] = "attachment; filename=\"#{result[:filename]}\""
                  response.body = result[:content]
                end
              end
            end
          end
        end
      end
    end
  end
end
