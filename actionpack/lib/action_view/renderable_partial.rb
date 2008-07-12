module ActionView
  module RenderablePartial
    # NOTE: The template that this mixin is beening include into is frozen
    # So you can not set or modify any instance variables

    def render(view, local_assigns = {})
      ActionController::Base.benchmark("Rendered #{path_without_format_and_extension}", Logger::DEBUG, false) do
        super
      end
    end

    def render_partial(view, variable_name, object = nil, local_assigns = {}, as = nil)
      object ||= view.controller.instance_variable_get("@#{variable_name}") if view.respond_to?(:controller)
      local_assigns[:object] ||= local_assigns[variable_name] ||= object
      local_assigns[as] ||= local_assigns[:object] if as
      render_template(view, local_assigns)
    end
  end
end
