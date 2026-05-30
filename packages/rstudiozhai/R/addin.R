required_workbench_packages <- function() {
  c("rstudioapi", "shiny", "miniUI")
}

check_workbench_dependencies <- function(required = required_workbench_packages()) {
  missing <- required[
    !vapply(required, requireNamespace, logical(1), quietly = TRUE)
  ]

  list(
    ok = length(missing) == 0L,
    missing = missing
  )
}

format_workbench_result <- function(response) {
  validate_ai_response(response)

  warnings <- if (length(response$warnings)) {
    paste0(
      "\n\nWarnings:\n",
      paste0("- ", response$warnings, collapse = "\n")
    )
  } else {
    ""
  }

  proposed <- if (length(response$proposed_files)) {
    names <- names(response$proposed_files)
    if (is.null(names)) {
      names <- rep("", length(response$proposed_files))
    }
    labels <- ifelse(nzchar(names), names, paste0("file_", seq_along(response$proposed_files)))
    paste0(
      "\n\nProposed files:\n",
      paste0("- ", labels, collapse = "\n")
    )
  } else {
    ""
  }

  paste0(response$content, warnings, proposed)
}

create_workbench_app <- function(provider_fun = NULL,
                                 provider_name = "local",
                                 context_collector = collect_rstudio_context) {
  provider_choices <- provider_choice_labels()
  if (is.function(provider_fun) && !provider_name %in% unname(provider_choices)) {
    provider_choices <- c(
      provider_choices,
      stats::setNames(provider_name, paste0("Custom Provider [", provider_name, "]"))
    )
  }
  selected_provider <- if (provider_name %in% unname(provider_choices)) {
    provider_name
  } else {
    unname(provider_choices[[1L]])
  }

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("RStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0"),
    miniUI::miniContentPanel(
      shiny::tabsetPanel(
        id = "view",
        shiny::tabPanel(
          "\u4efb\u52a1",
          shiny::textAreaInput(
            "task",
            "\u4f60\u5e0c\u671b AI \u5e2e\u4f60\u505a\u4ec0\u4e48\uff1f",
            value = "\u68c0\u67e5\u5f53\u524d RStudio \u73af\u5883\u5e76\u7ed9\u51fa\u5efa\u8bae",
            width = "100%",
            height = "120px"
          ),
          shiny::selectInput(
            "provider",
            "AI Provider",
            choices = provider_choices,
            selected = selected_provider
          ),
          shiny::verbatimTextOutput("provider_status"),
          shiny::selectInput(
            "mode",
            "\u4efb\u52a1\u6a21\u5f0f",
            choices = c("diagnose", "explain", "edit", "generate"),
            selected = "diagnose"
          ),
          shiny::checkboxInput(
            "allow_code_execution",
            "\u5141\u8bb8\u6267\u884c\u4ee3\u7801",
            value = FALSE
          ),
          shiny::checkboxInput(
            "require_user_confirmation",
            "\u5199\u5165\u6216\u6267\u884c\u524d\u9700\u8981\u6211\u786e\u8ba4",
            value = TRUE
          ),
          shiny::actionButton("run", "\u751f\u6210\u8bf7\u6c42"),
          shiny::actionButton("create_report", "\u751f\u6210 Quarto \u8349\u7a3f"),
          shiny::hr(),
          shiny::verbatimTextOutput("result"),
          shiny::verbatimTextOutput("report_result")
        ),
        shiny::tabPanel(
          "\u73af\u5883\u4f53\u68c0",
          shiny::actionButton("refresh_diagnostics", "\u5237\u65b0\u4f53\u68c0"),
          shiny::hr(),
          shiny::verbatimTextOutput("diagnostics")
        ),
        shiny::tabPanel(
          "\u77e5\u8bc6\u5e93",
          shiny::textInput(
            "knowledge_query",
            "\u641c\u7d22 RStudio \u672f\u8bed\u3001\u547d\u4ee4\u6216 R \u62a5\u9519",
            value = "object not found"
          ),
          shiny::actionButton("search_knowledge", "\u641c\u7d22"),
          shiny::hr(),
          shiny::verbatimTextOutput("knowledge_result")
        ),
        shiny::tabPanel(
          "\u914d\u7f6e",
          shiny::selectInput(
            "provider_config_provider",
            "Provider",
            choices = provider_choices,
            selected = selected_provider
          ),
          shiny::hr(),
          shiny::tags$h4("OpenAI Responses"),
          shiny::passwordInput("openai_api_key", "OPENAI_API_KEY", value = ""),
          shiny::textInput("openai_model", "RSTUDIOZHAI_OPENAI_MODEL", value = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = "")),
          shiny::textInput(
            "openai_base_url",
            "RSTUDIOZHAI_OPENAI_BASE_URL",
            value = Sys.getenv("RSTUDIOZHAI_OPENAI_BASE_URL", unset = "https://api.openai.com/v1")
          ),
          shiny::hr(),
          shiny::tags$h4("Compatible Chat Gateway"),
          shiny::selectInput(
            "gateway_preset",
            "Gateway preset",
            choices = provider_gateway_preset_choices(),
            selected = "ollama"
          ),
          shiny::passwordInput("gateway_api_key", "RSTUDIOZHAI_GATEWAY_API_KEY", value = ""),
          shiny::textInput("gateway_model", "RSTUDIOZHAI_GATEWAY_MODEL", value = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = "")),
          shiny::textInput(
            "gateway_base_url",
            "RSTUDIOZHAI_GATEWAY_BASE_URL",
            value = Sys.getenv("RSTUDIOZHAI_GATEWAY_BASE_URL", unset = "http://127.0.0.1:11434/v1")
          ),
          shiny::textInput(
            "gateway_endpoint",
            "RSTUDIOZHAI_GATEWAY_ENDPOINT",
            value = Sys.getenv("RSTUDIOZHAI_GATEWAY_ENDPOINT", unset = "/chat/completions")
          ),
          shiny::actionButton("apply_gateway_preset", "\u5e94\u7528\u7f51\u5173\u9884\u8bbe"),
          shiny::actionButton("gateway_checklist", "\u751f\u6210\u8054\u8c03\u6e05\u5355"),
          shiny::selectInput(
            "provider_compatibility_target_type",
            "Compatibility target type",
            choices = c(
              "all",
              "offline",
              "openai_api",
              "local_gateway",
              "cloud_gateway",
              "enterprise_gateway"
            ),
            selected = "all"
          ),
          shiny::actionButton("provider_compatibility", "\u67e5\u770b\u517c\u5bb9\u6027\u77e9\u9635"),
          shiny::actionButton("apply_provider_config", "\u5e94\u7528\u914d\u7f6e"),
          shiny::actionButton("probe_provider_config", "\u63a2\u6d4b\u6a21\u578b"),
          shiny::selectInput("probe_model_choice", "\u63a2\u6d4b\u5230\u7684\u6a21\u578b", choices = character()),
          shiny::actionButton("use_probe_model", "\u4f7f\u7528\u9009\u4e2d\u6a21\u578b"),
          shiny::actionButton("provider_report", "\u751f\u6210\u8054\u8c03\u62a5\u544a"),
          shiny::hr(),
          shiny::verbatimTextOutput("provider_config_status"),
          shiny::verbatimTextOutput("provider_probe_result"),
          shiny::verbatimTextOutput("provider_report_result"),
          shiny::verbatimTextOutput("gateway_checklist_result"),
          shiny::verbatimTextOutput("provider_compatibility_result")
        )
      ),
    )
  )

  server <- function(input, output, session) {
    provider_config_values <- function() {
      list(
        openai_api_key = input$openai_api_key,
        openai_model = input$openai_model,
        openai_base_url = input$openai_base_url,
        gateway_api_key = input$gateway_api_key,
        gateway_model = input$gateway_model,
        gateway_base_url = input$gateway_base_url,
        gateway_endpoint = input$gateway_endpoint
      )
    }

    selected_provider_fun <- function(provider) {
      if (is.function(provider_fun) && identical(provider, provider_name)) {
        return(provider_fun)
      }
      if (provider %in% c("openai_responses", "compatible_chat")) {
        return(provider_from_config(provider, build_provider_config(provider, provider_config_values())))
      }
      resolve_ai_provider(provider)
    }

    selected_provider_status <- function(provider) {
      if (is.function(provider_fun) && identical(provider, provider_name) && !provider %in% list_ai_providers()$provider) {
        return(list(
          ok = TRUE,
          provider = provider,
          label = provider,
          needs_network = NA,
          needs_config = NA,
          missing = character(),
          has_api_key = FALSE,
          model = "",
          base_url = "",
          message = "\u5df2\u6ce8\u5165\u81ea\u5b9a\u4e49 Provider\u3002"
        ))
      }
      if (provider %in% c("openai_responses", "compatible_chat")) {
        return(provider_config_status_from_values(provider, provider_config_values()))
      }
      provider_config_status(provider)
    }

    diagnostics <- shiny::eventReactive(
      input$refresh_diagnostics,
      collect_environment_report(),
      ignoreNULL = FALSE
    )

    output$provider_status <- shiny::renderText({
      provider <- if (is.null(input$provider)) selected_provider else input$provider
      format_provider_status(selected_provider_status(provider))
    })

    output$provider_config_status <- shiny::renderText({
      provider <- if (is.null(input$provider_config_provider)) selected_provider else input$provider_config_provider
      format_provider_status(selected_provider_status(provider))
    })

    shiny::observeEvent(input$apply_provider_config, {
      provider <- if (is.null(input$provider_config_provider)) selected_provider else input$provider_config_provider
      shiny::updateSelectInput(session, "provider", selected = provider)
    })

    shiny::observeEvent(input$apply_gateway_preset, {
      values <- provider_values_from_gateway_preset(
        preset = if (is.null(input$gateway_preset)) "ollama" else input$gateway_preset,
        model = input$gateway_model,
        api_key = input$gateway_api_key
      )
      shiny::updateSelectInput(session, "provider_config_provider", selected = "compatible_chat")
      shiny::updateSelectInput(session, "provider", selected = "compatible_chat")
      shiny::updateTextInput(session, "gateway_model", value = values$gateway_model)
      shiny::updateTextInput(session, "gateway_base_url", value = values$gateway_base_url)
      shiny::updateTextInput(session, "gateway_endpoint", value = values$gateway_endpoint)
    })

    provider_probe <- shiny::eventReactive(input$probe_provider_config, {
      provider <- if (is.null(input$provider_config_provider)) selected_provider else input$provider_config_provider
      probe_provider_models(provider, config = build_provider_config(provider, provider_config_values()))
    })

    shiny::observeEvent(provider_probe(), {
      shiny::updateSelectInput(session, "probe_model_choice", choices = provider_model_choices(provider_probe()))
    })

    shiny::observeEvent(input$use_probe_model, {
      provider <- if (is.null(input$provider_config_provider)) selected_provider else input$provider_config_provider
      values <- apply_provider_model_choice(provider, provider_config_values(), input$probe_model_choice)
      if (!is.null(values$openai_model)) {
        shiny::updateTextInput(session, "openai_model", value = values$openai_model)
      }
      if (!is.null(values$gateway_model)) {
        shiny::updateTextInput(session, "gateway_model", value = values$gateway_model)
      }
    })

    output$provider_probe_result <- shiny::renderText({
      shiny::req(input$probe_provider_config)
      format_provider_probe(provider_probe())
    })

    provider_report <- shiny::eventReactive(input$provider_report, {
      provider <- if (is.null(input$provider_config_provider)) selected_provider else input$provider_config_provider
      collect_provider_integration_report(
        provider,
        values = provider_config_values(),
        include_environment = TRUE,
        include_extension = TRUE
      )
    })

    output$provider_report_result <- shiny::renderText({
      shiny::req(input$provider_report)
      format_provider_integration_report(provider_report())
    })

    gateway_checklist <- shiny::eventReactive(input$gateway_checklist, {
      collect_provider_integration_checklist(
        preset = if (is.null(input$gateway_preset)) "ollama" else input$gateway_preset,
        model = input$gateway_model,
        base_url = input$gateway_base_url,
        endpoint = input$gateway_endpoint,
        api_key = input$gateway_api_key
      )
    })

    output$gateway_checklist_result <- shiny::renderText({
      shiny::req(input$gateway_checklist)
      format_provider_integration_checklist(gateway_checklist())
    })

    provider_compatibility <- shiny::eventReactive(input$provider_compatibility, {
      filter_provider_compatibility_matrix(
        provider_compatibility_matrix(),
        target_type = input$provider_compatibility_target_type
      )
    })

    output$provider_compatibility_result <- shiny::renderText({
      shiny::req(input$provider_compatibility)
      format_provider_compatibility_matrix(provider_compatibility())
    })

    result <- shiny::eventReactive(input$run, {
      report <- diagnostics()
      rstudio_context <- context_collector()
      provider <- if (is.null(input$provider)) selected_provider else input$provider
      status <- selected_provider_status(provider)
      if (!isTRUE(status$ok)) {
        stop(format_provider_status(status), call. = FALSE)
      }
      request <- build_ai_task_request(
        task = input$task,
        mode = input$mode,
        provider = provider,
        context = list(
          environment = report,
          rstudio = rstudio_context
        ),
        allow_code_execution = isTRUE(input$allow_code_execution),
        require_user_confirmation = isTRUE(input$require_user_confirmation)
      )
      invoke_ai_provider(request, selected_provider_fun(provider))
    })

    output$result <- shiny::renderText({
      res <- result()
      format_workbench_result(res)
    })

    report_result <- shiny::eventReactive(input$create_report, {
      res <- shiny::req(result())
      context <- context_collector()
      project_path <- if (is.list(context) && nzchar(context$project_path)) {
        context$project_path
      } else {
        getwd()
      }
      create_quarto_report(
        task = input$task,
        ai_result = res$content,
        output_dir = file.path(project_path, "reports"),
        title = "RStudio Chinese AI Workbench Report",
        include_environment = TRUE
      )
    })

    output$report_result <- shiny::renderText({
      report <- report_result()
      paste0("Quarto report: ", report$path)
    })

    output$diagnostics <- shiny::renderText({
      format_environment_report(diagnostics())
    })

    knowledge_result <- shiny::eventReactive(
      input$search_knowledge,
      summarize_knowledge_for_query(input$knowledge_query),
      ignoreNULL = FALSE
    )

    output$knowledge_result <- shiny::renderText({
      knowledge_result()
    })

    shiny::observeEvent(input$done, {
      shiny::stopApp(invisible(TRUE))
    })
  }

  list(ui = ui, server = server)
}

run_workbench <- function(provider_fun = NULL,
                          provider_name = "local") {
  deps <- check_workbench_dependencies()

  if (!isTRUE(deps$ok)) {
    report <- collect_environment_report()
    message(format_environment_report(report))
    stop(
      "\u7f3a\u5c11\u8fd0\u884c RStudio Addin UI \u6240\u9700\u7684\u5305\uff1a",
      paste(deps$missing, collapse = ", "),
      "\u3002\u8bf7\u5148\u5b89\u88c5\u8fd9\u4e9b\u5305\u3002",
      call. = FALSE
    )
  }

  app <- create_workbench_app(provider_fun = provider_fun, provider_name = provider_name)
  viewer <- shiny::dialogViewer("RStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0", width = 900, height = 700)
  shiny::runGadget(app$ui, app$server, viewer = viewer)
}
