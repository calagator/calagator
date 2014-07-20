# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Calagator::Application.config.secret_token = SECRETS.session_secret || '4822c519d5cceb8f4ad7e31bf4801c1d4d98449178d35a7f2bf3725b0aa9aa6d6e1a512b682fb30eb6cab4a92fe24230774004e1564d0386cdad6330065a8b0a'
