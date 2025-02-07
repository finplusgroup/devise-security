# frozen_string_literal: true

require 'test_helper'

class TestWithSecurityQuestion < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  tests SecurityQuestion::UnlocksController

  setup do
    @user = SecurityQuestionUser.create!(
      username: 'hello', email: 'hello@microsoft.com', password: 'A1234567z!', security_question_answer: 'Right Answer'
    )
    @user.lock_access!
    assert @user.locked_at.present?
    @request.env['devise.mapping'] = Devise.mappings[:security_question_user]
  end

  test 'When security question is enabled, it is inserted correctly' do
    post(
      :create,
      params: {
        security_question_answer: 'wrong answer',
        security_question_user: {
          email: @user.email
        }
      }
    )
    assert_equal I18n.t('devise.invalid_security_question'), flash[:alert]
    assert_redirected_to new_security_question_user_unlock_path
  end

  test 'When security_question is valid, it runs as normal' do
    post(
      :create,
      params: {
        security_question_answer: @user.security_question_answer,
        security_question_user: {
          email: @user.email
        }
      }
    )

    assert_equal I18n.t('devise.unlocks.send_instructions'), flash[:notice]
    assert_redirected_to new_security_question_user_session_path
  end
end

class TestWithoutSecurityQuestion < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  tests Devise::UnlocksController

  setup do
    @user = User.create(
      username: 'hello', email: 'hello@path.travel', password: '1234', security_question_answer: 'Right Answer'
    )
    @user.lock_access!
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  test 'When security question is not enabled it is not inserted' do
    post :create, params: { user: { email: @user.email } }

    assert_equal I18n.t('devise.unlocks.send_instructions'), flash[:notice]
    assert_redirected_to new_user_session_path
  end
end
