# -*- coding: utf-8 -*-
class StripePaymentsController < ApplicationController

  def index
  end

  def setup
    puts "*** setup ***" 
    #content_type 'application/json'
    {
      publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'],
      basicPrice: ENV['BASIC_PRICE_ID'],
      proPrice: ENV['PRO_PRICE_ID']
    }.to_json
  end

  def create_checkout_session 
    #content_type 'application/json'
    data = JSON.parse(request.body.read) 
    puts " "
    puts "create_checkout_session"
    puts "***** data: " + data.inspect
    puts "***** data['priceId']: " + data['priceId'].inspect
    puts "***** DOMAIN: " + ENV['DOMAIN']

    # Create new Checkout Session for the order
    # Other optional params include:
    # [billing_address_collection] - to display billing address details on the page
    # [customer] - if you have an existing Stripe Customer ID
    # [customer_email] - lets you prefill the email input in the form
    # For full details see https://stripe.com/docs/api/checkout/sessions/create
    # ?session_id={CHECKOUT_SESSION_ID} means the redirect will have the session ID set as a query param
    begin
      session = Stripe::Checkout::Session.create(
        success_url: ENV['DOMAIN'] + '/success?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: ENV['DOMAIN'] + '/canceled',
        payment_method_types: ['card'],
        mode: 'subscription',
        line_items: [{
          quantity: 1,
          price: data['priceId'],
        }],
      )
      puts "***** session_id: " + session.id.inspect
    rescue => e
      puts "halt"
      #puts "*** e ***" + e.inspect
      #halt 400,
      #  { 'Content-Type' => 'application/json' },
      #  { 'error': { message: e.error.message } }.to_json
    end
    {
      sessionId: session.id
    }.to_json
  end

  #Fetch the Checkout Session to display the JSON result on the success page
  def checkout_session
    puts "*** checkout_session ***"
    #content_type 'application/json'
    session_id = params[:sessionId]

    session = Stripe::Checkout::Session.retrieve(session_id)

    puts "session: " + session.inspect
    session.to_json
  end

  def customer_portal
    content_type 'application/json'
    data = JSON.parse(request.body.read)

    # For demonstration purposes, we're using the Checkout session to retrieve the customer ID.
    # Typically this is stored alongside the authenticated user in your database.
    checkout_session_id = data['sessionId']
    checkout_session = Stripe::Checkout::Session.retrieve(checkout_session_id)

    # This is the URL to which users will be redirected after they are done
    # managing their billing.
    return_url = ENV['DOMAIN']

    session = Stripe::BillingPortal::Session.create({
      customer: checkout_session['customer'],
      return_url: return_url
    })

    {
      url: session.url
    }.to_json
  end

  def webhook
    # You can use webhooks to receive information about asynchronous payment events.
    # For more about our webhook events check out https://stripe.com/docs/webhooks.
    webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
    payload = request.body.read
    if !webhook_secret.empty?
      # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      event = nil

      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, webhook_secret
        )
      rescue JSON::ParserError => e
        # Invalid payload
        status 400
        return
      rescue Stripe::SignatureVerificationError => e
        # Invalid signature
        puts '⚠️  Webhook signature verification failed.'
        status 400
        return
      end
    else
      data = JSON.parse(payload, symbolize_names: true)
      event = Stripe::Event.construct_from(data)
    end
    # Get the type of webhook event sent - used to check the status of PaymentIntents.
    event_type = event['type']
    data = event['data']
    data_object = data['object']

    puts '🔔  Payment succeeded!' if event_type == 'checkout.session.completed'

    content_type 'application/json'
    {
      status: 'success'
    }.to_json
  end
 
end
