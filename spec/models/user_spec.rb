require 'rails_helper'

RSpec.describe User, type: :model do
  subject { described_class.new(email_address: '  TEST@Example.com  ', password: 'password123') }

  it 'is valid with valid attributes' do
    expect(subject).to be_valid
  end

  it 'requires email_address to be present' do
    subject.email_address = nil
    expect(subject).not_to be_valid
  end

  it 'requires email_address to be unique' do
    described_class.create!(email_address: 'test@example.com', password: 'password123')
    user2 = described_class.new(email_address: 'test@example.com', password: 'password123')
    expect(user2).not_to be_valid
  end

  it 'requires password_digest to be present' do
    subject.password_digest = nil
    expect(subject).not_to be_valid
  end

  it 'authenticates with correct password' do
    subject.save!
    expect(subject.authenticate('password123')).to eq(subject)
    expect(subject.authenticate('wrong')).to be_falsey
  end

  it 'has many sessions' do
    assoc = described_class.reflect_on_association(:sessions)
    expect(assoc.macro).to eq :has_many
  end

  it 'normalizes email_address (downcase and strip)' do
    subject.save!
    expect(subject.reload.email_address).to eq('test@example.com')
  end
end
