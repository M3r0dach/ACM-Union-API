class Api::V1::SpidersController < ApplicationController

  before_action :authenticate_user, except: [:accounts, :submits]

  def accounts
    optional! :page, default: 1
    optional! :per, default: 15, values: 1..150
    optional! :sort_field, default: :id
    optional! :sort_order, default: :ascend, values: %w(ascend descend)

    @accounts = Account.with_search(params).with_filters(params).with_sort(params)
    @accounts = @accounts.includes(:user).page(params[:page]).per(params[:per])
    render json: @accounts, root: 'items', meta: meta_with_page(@accounts)
  end

  def create_account
    if Account.exists?(oj_name: account_params[:oj_name], user_id: current_user.id)
      render json: { error_code: 1, message: '账号已存在' } and return
    end
    @account = Account.new(account_params)
    @account[:user_id] = current_user.id
    if @account.save!
      render json: @account
    else
      render json: { error_code: 1 }
    end
  end

  def update_account
    @account = Account.find(params[:id])
    if @account.update(account_params)
      render json: @account
    else
      render json: { error_code: 1 }
    end
  end

  def delete_account
    @account = Account.find(params[:id])
    if @account.destroy
      render json: { error_code: 0 }
    else
      render json: { error_code: 1 }
    end
  end

  def submits
    optional! :page, default: 1
    optional! :per, default: 20, values: 1..500
    optional! :sort_field, default: :id
    optional! :sort_order, default: :ascend, values: %w(ascend descend)

    @submits = Submit.with_search(params).with_filters(params).with_sort(params)
    @submits = @submits.page(params[:page]).per(params[:per])
    render json: @submits, root: 'items', meta: meta_with_page(@submits)
  end

  def get_statistic(submits)
    accepted = submits.where(result: ['AC', 'OK', 'Accepted'])
    submitted_count = submits.group('user_name', 'user_id').count
    accepted_count = accepted.group('user_name', 'user_id').count
    statistic = submitted_count.map do |k,v|
      accepted = if accepted_count.include?(k)
        accepted_count[k]
      else
        0
      end
      {user_name: k[0], user_id: k[1], submitted: v, solved: accepted}
    end
    statistic.sort_by! do |x|
      -x[:solved]
    end
    statistic.each_with_index.map do |k, idx|
      k[:order] = idx+1
      k
    end
  end

  def week_rank
    this_week = Submit.where("YEARWEEK(date_format(submitted_at, '%Y-%m-%d'))=YEARWEEK(now())")
    last_week = Submit.where("YEARWEEK(date_format(submitted_at, '%Y-%m-%d'))=YEARWEEK(now())-1")
    this_week = get_statistic this_week
    last_week = get_statistic last_week
    render json: {this_week: this_week, last_week: last_week}
  end

  def workers
    @workers = SpiderService.get_open_spider_workers
    render json: @workers
  end

  def open_worker
    requires! :oj, values: Account::OJ_DICT.values

    oj_name = params[:oj]
    render json: SpiderService.open_spider_worker(oj_name)
  end

  def stop_worker
    requires! :oj, values: Account::OJ_DICT.values

    oj_name = params[:oj]
    render json: SpiderService.stop_spider_worker(oj_name)
  end

  def rank_list
    optional! :page, default: 1
    optional! :per, default: 15, values: 10..30

    @rank_list, @meta = SpiderService.get_rank_list(params[:page], params[:per])
    render json: {items: @rank_list, meta: @meta}
  end

  private

  def account_params
    params.permit(:nickname, :password, :oj_name, :user_id)
  end
end
