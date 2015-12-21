require 'rails_admin/adapters/active_record'

module RailsAdmin
  module Adapters
    module ActiveRecord
      class WhereBuilder
        def add(field, value, operator)
          field.searchable_columns.flatten.each do |column_infos|
            if value.is_a?(Array)
              value = value.map { |v| field.parse_value(v) }
            else
              value = field.parse_value(value)
            end
            column =
              if @scope.model.try(:translated?, field.name)
                @scope.model.translated_column_name(field.name)
              else
                column_infos[:column]
              end
            statement, value1, value2 = StatementBuilder.new(column, column_infos[:type], value, operator).to_statement
            @statements << statement if statement.present?
            @values << value1 unless value1.nil?
            @values << value2 unless value2.nil?
            table, column = column_infos[:column].split('.')
            @tables.push(table) if column
          end
        end

        def build
          scope = @scope.where(@statements.join(' OR '), *@values)
          scope = scope.with_translations(::I18n.locale) if @scope.model.try(:translates?)
          scope = scope.references(*(@tables.uniq)) if @tables.any?
          scope
        end
      end
    end
  end
end
