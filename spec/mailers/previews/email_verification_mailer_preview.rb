# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/email_verification_mailer/verify_email
  def verify_email
    user = User.new(
      email_address: 'test@example.com',
      first_name: 'John',
      last_name: 'Doe'
    )
    user.generate_verification_token

    EmailVerificationMailer.verify_email(user)
  end
end
