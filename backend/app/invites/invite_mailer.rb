# frozen_string_literal: true

require "mail"

module Backend
  module Invites
    class InviteMailer
      def self.deliver(invite:, plaintext_token:, project:, invited_by_user:)
        settings = Hanami.app["settings"]
        account = project.account
        layout = Backend::Emails::BrandedLayout

        link = "#{settings.frontend_base_url}/accept-invite?token=#{plaintext_token}"
        inviter = invited_by_user ? " by #{invited_by_user.email}" : ""
        title = "You've been invited to #{project.name}"
        message = "You've been invited#{inviter} to join the \"#{project.name}\" project on x-locality as " \
          "#{invite.role}. This link expires in 7 days. If you weren't expecting this, you can ignore this email."

        body_text = "#{message}\n\nAccept the invite and set your password here:\n#{link}"
        body_html = "<p>#{layout.escape(message)}</p>" \
          "<p><a href=\"#{layout.escape(link)}\" style=\"display:inline-block;padding:10px 20px;" \
          "background:#1a8f72;color:#ffffff;border-radius:6px;text-decoration:none;\">Accept invite</a></p>"

        Mail.deliver do
          delivery_method :smtp, address: settings.smtp_host, port: settings.smtp_port

          from layout.from_header(account)
          to invite.email
          subject "x-locality: #{title}"

          text_part { body layout.text(account: account, title: title, body_text: body_text) }
          html_part do
            content_type "text/html; charset=UTF-8"
            body layout.html(account: account, title: title, body_html: body_html)
          end
        end
      end
    end
  end
end
