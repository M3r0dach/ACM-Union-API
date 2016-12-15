class Api::V1::AuthController < ApplicationController

  def token
    ident = login_params[:nickname]
    api_error! and return if ident.blank?

    user = User.find_by(nickname: ident)
    if user.blank?
      user_info = UserInfo.find_by('email = ? OR stu_id = ?', ident, ident)
      user = user_info.user if user_info.present?
    end
    if user.present? && user.authenticate(login_params[:password])
      expires = AcmUnionApi::TOKEN_EXPIRES
      render json: { token: user.token(expires), expire_time: expires }
    else
      api_error!
    end
  end

  private

  def login_params
    params.permit(:nickname, :password)
  end

end