# ---------------------------------------------------------------------------
# Documentation workflow
# ---------------------------------------------------------------------------

set-movie: _require-movie
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@echo $(MOVIE) > $(WORKFLOW_DIR)/.movie
	@echo "Movie type set to: $(MOVIE)"

show-movie:
	@if [ -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "Current movie: $$(cat $(WORKFLOW_DIR)/.movie)"; \
	else \
		echo "No movie set. Use: make set-movie MOVIE=longplay"; \
	fi

prepare-batch:
	@if [ ! -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "ERROR: no movie set. Run: make set-movie MOVIE=longplay"; exit 1; \
	fi
	@$(PYTHON) $(RUN_SCRIPT) workflow.prepare_batch \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv \
		--count $(BATCH_COUNT) \
		--output $(WORKFLOW_DIR)/batch_procedures.txt --source $(SRC)

rename:
	@if [ ! -f $(WORKFLOW_DIR)/rename_batch.csv ]; then \
		echo "ERROR: $(WORKFLOW_DIR)/rename_batch.csv not found."; \
		echo "Create it with columns: old_name,new_name,description"; exit 1; \
	fi
	@$(PYTHON) $(RUN_SCRIPT) workflow.rename_procedures \
		--source $(SRC) --database $(WORKFLOW_DIR)/rename_batch.csv \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv
	@echo "Renames applied. A new name can change a shared label column,"
	@echo "so run: make format && make verify"
