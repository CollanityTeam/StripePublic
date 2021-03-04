Rails.configuration.stripe = {
    :publishable_key => "<MY-PUBLISHABLE-KEY>",
    :secret_key      => "<MY-SECRET-KEY>"
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
