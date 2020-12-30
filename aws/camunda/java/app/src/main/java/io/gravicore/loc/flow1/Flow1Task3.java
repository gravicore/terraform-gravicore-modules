package io.gravicore.loc.flow1;

import org.camunda.bpm.engine.delegate.DelegateExecution;
import org.camunda.bpm.engine.delegate.JavaDelegate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class Flow1Task3 implements JavaDelegate {

    private static final Logger LOGGER = LoggerFactory.getLogger(Flow1Task3.class);

    @Override
    public void execute(final DelegateExecution execution) {
        LOGGER.info("Task3 variables = {}", execution.getVariables());
    }
}
