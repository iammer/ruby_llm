# frozen_string_literal: true

module RubyLLM
  module Providers
    module OpenRouter
      # Reasoning methods of the OpenRouter API integration
      module Reasoning
        module_function

        def render_payload(messages, tools:, temperature:, model:, stream: false, reasoning: false)
          payload = {
            model: model,
            messages: format_messages(messages),
            stream: stream
          }

          # Only include temperature if it's not nil (some models don't accept it)
          payload[:temperature] = temperature unless temperature.nil?
          payload[:reasoning] = { effort: reasoning } if reasoning

          if tools.any?
            payload[:tools] = tools.map { |_, tool| tool_for(tool) }
            payload[:tool_choice] = 'auto'
          end

          payload[:stream_options] = { include_usage: true } if stream
          payload
        end

        def parse_completion_response(response)
          data = response.body
          return if data.empty?

          raise Error.new(response, data.dig('error', 'message')) if data.dig('error', 'message')

          message_data = data.dig('choices', 0, 'message')
          return unless message_data

          Message.new(
            role: :assistant,
            content: message_data['content'],
            tool_calls: parse_tool_calls(message_data['tool_calls']),
            input_tokens: data['usage']['prompt_tokens'],
            output_tokens: data['usage']['completion_tokens'],
            model_id: data['model'],
            reasoning: message_data['reasoning']
          )
        end
      end
    end
  end
end
