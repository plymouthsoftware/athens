require 'bigdecimal'

module Athens
  class Connection
    attr_reader :database_name
    attr_reader :client

    def initialize(database: nil, aws_client_override: {})
      @database_name = database

      client_config = {
        access_key_id: Athens.configuration.aws_access_key,
        secret_access_key: Athens.configuration.aws_secret_key,
        region: Athens.configuration.aws_region,
        profile: Athens.configuration.aws_profile
      }.merge(aws_client_override).compact

      @client = Aws::Athena::Client.new(client_config)
    end

    # Runs a query against Athena, returning an Athens::Query object
    # that you can use to wait for it to finish or get the results
    def execute(query, request_token: nil, work_group: nil, result_reuse_configuration: nil)
      if @database_name
        resp = @client.start_query_execution(
          query_string: query,
          query_execution_context: context,
          result_configuration: result_config,
          client_request_token: request_token,
          work_group: work_group,
          result_reuse_configuration: result_reuse_configuration,
        )
      else
        resp = @client.start_query_execution(
          query_string: query,
          result_configuration: result_config,
          reuse_configuration: reuse_configuration,
        )
      end

      return Athens::Query.new(self, resp.query_execution_id)
    end

    private

      def context
        Aws::Athena::Types::QueryExecutionContext.new(database: @database_name)
      end

      def result_config
        Aws::Athena::Types::ResultConfiguration.new(
          output_location: Athens.configuration.output_location,
          encryption_configuration: Athens.configuration.result_encryption
        )
      end

  end
end
