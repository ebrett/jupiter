class EmailVerificationMailer < ApplicationMailer
  default from: "noreply@jupiter.example.com"

  def verify_email(user)
    @user = user
    @verification_url = verify_email_url(token: @user.verification_token)

    mail(
      to: @user.email_address,
      subject: "Verify your Jupiter account email address"
    )
  end
end
