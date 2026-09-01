# frozen_string_literal: true

require 'cgi'

module Backend
  module Emails
    # Named Emails, not Mail - Backend::Mail would shadow the top-level
    # ::Mail gem constant via Ruby's lexical scoping inside any Backend::*
    # class that calls Mail.deliver, once Zeitwerk registers it as an
    # autoloadable namespace.
    #
    # Shared HTML/text wrapper every outgoing email renders through, so an
    # account's logo and chosen sender name show up consistently across
    # budget alerts, test alerts, and invites without each mailer
    # duplicating the branding markup.
    module BrandedLayout
      module_function

      def from_name(account)
        name = account.correspondence_name
        name = account.name if name.nil? || name.strip.empty?
        name
      end

      def from_header(account)
        "#{from_name(account)} <#{Hanami.app['settings'].mail_from}>"
      end

      def logo_url(account)
        url = account.logo_url
        url.nil? || url.strip.empty? ? default_logo_url : url
      end

      def default_logo_url
        "#{Hanami.app['settings'].frontend_base_url}/xlocality-logo.svg"
      end

      def html(account:, title:, body_html:)
        sender = escape(from_name(account))
        <<~HTML
          <!DOCTYPE html>
          <html>
            <body style="margin:0;padding:0;background:#f4f4f5;font-family:-apple-system,Helvetica,Arial,sans-serif;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:32px 0;">
                <tr>
                  <td align="center">
                    <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:8px;overflow:hidden;">
                      <tr>
                        <td style="padding:24px 32px 0;">
                          <img src="#{escape(logo_url(account))}" alt="#{sender}" height="32" style="height:32px;width:auto;">
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:16px 32px 32px;color:#18181b;font-size:14px;line-height:1.5;">
                          <h1 style="font-size:18px;margin:0 0 16px;">#{escape(title)}</h1>
                          #{body_html}
                        </td>
                      </tr>
                    </table>
                    <p style="color:#71717a;font-size:12px;margin-top:16px;">Sent by #{sender} via XLocality</p>
                  </td>
                </tr>
              </table>
            </body>
          </html>
        HTML
      end

      def text(account:, title:, body_text:)
        "#{title}\n\n#{body_text}\n\n--\nSent by #{from_name(account)} via XLocality"
      end

      def escape(str)
        CGI.escapeHTML(str.to_s)
      end
    end
  end
end
