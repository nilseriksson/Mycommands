class Controller
  attr_accessor :model, :view, :application, :history
  def initialize
    name = self.class.to_s.gsub('Controller', '')
    @model = Factory::get(name+'Model')
    @view = Factory::get(name+'View')
    @application =  Factory::get(:Application)
    @history =  Factory::get(:HistoryModel)
  end
end

class CategoryController < Controller
  def browse choice = nil
    puts @model.count
    puts choice
#    if @model.count < choice
    begin
      categories = @model.categories
    rescue
      Factory::get(:CommandController).read choice.to_i-@model.count
    end
    category = @model.last_category
    if categories
      @view.display_list(categories, category)
      Factory::get(:CommandController).browse(category, @model.count)
      @application.input_to 'Category', 'browse'
    else
      @application.dispatch('Command', 'browse', category)
    end
  end
end

class CommandController < Controller
  def browse category, offset = 0
    @model.category = category
    commands = @model.commands
    @view.display_list(commands, category, offset) unless commands.empty?
    @application.input_to 'Command', 'read' if offset == 0
  end

  def read choice
    @model.set_command(choice.to_i-1)
    @application.dispatch('Param', 'read')
    @application.input_to('Param', 'edit')
  end

  def edit
    params = Factory::get('ParamModel')
    command = @model.command_string
    params.substituted_params.each do |param|
      param_description, param_value, input = param
      if input.empty? and param_description.include? "("
        input = param_description[/\((.*?)\)/, 1]
      end
      command.gsub!(param_value, input)
    end
    Clipboard.copy command
    exit
  end
end

class ParamController < Controller
  def read
    if param = @model.params_pop
      @view.display_item param.keys.to_s
    else
      @application.dispatch('Command', 'edit')
    end
  end

  def edit input
    @model.substituted_params.push(@model.param.to_a.flatten.push(input))
    @application.dispatch('Param', 'read')
  end
end

