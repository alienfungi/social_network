class MessagesController < ApplicationController
  before_action :set_message, only: [:show, :destroy]
  before_action :correct_users?, only: [:show, :destroy]

  def index
    populate_messages
    prep_new_message
  end

  def received
    session[:active_tab] = 'received'
    redirect_to messages_path
  end

  def sent
    session[:active_tab] = 'sent'
    redirect_to messages_path
  end

  def show
    @message.update_attribute(:read, true) if @message.recipient == current_user
  end

  def new
    session[:active_tab] = 'new'
    redirect_to messages_path(recipient: params[:recipient])
  end

  def create
    @message = current_user.sent_messages.build(message_params)
    return_to = session.delete(:return_to)
    if @message.save
      session[:active_tab] = 'sent'
      flash[:success] = "Message sent."
      track_activity @message, [@message.recipient, @message.sender]
      redirect_to messages_path
    else
      session[:message] = message_params
      session[:active_tab] = 'new'
      flash.now[:error] = "Message failed to send." if @message.valid?
      populate_messages if params[:page] == "index"
      if params[:page]
        render params.delete(:page)
      else
        redirect_to :back
      end
    end
  end

  def destroy
    session[:active_tab] = @message.recipient == current_user ? 'received' : 'sent'
    @message_id = @message.id
    @message.remove_user(current_user)
    respond_to do |format|
      format.html do
        flash[:success] = "Message deleted."
        redirect_to messages_path
      end
      format.js do
      end
    end
  end

private

  def message_params
    params.require(:message).permit(:recipient_identifier, :subject, :message)
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def correct_users?
    validate_users(@message.recipient, @message.sender)
  end

  def prep_new_message
    if session[:message]
      @message = Message.new(session.delete(:message))
    elsif params[:recipient]
      recipient = params[:recipient]
      @message = Message.new(recipient_identifier: recipient)
    else
      @message = Message.new
    end
  end

  def populate_messages
    @received_messages = current_user.received_messages.includes(:sender).where(
      removed_by_recipient: false
    ).paginate( page: params[:received_messages_page])

    @sent_messages = current_user.sent_messages.includes(:recipient).where(
      removed_by_sender: false
    ).paginate(page: params[:sent_messages_page])

    @active_tab = session.delete(:active_tab) ||  params.delete(:active_tab) || "received"
  end

end
