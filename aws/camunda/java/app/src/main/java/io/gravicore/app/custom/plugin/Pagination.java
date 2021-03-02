package io.gravicore.app.custom.plugin;

import org.camunda.bpm.engine.impl.Page;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.util.Collections;
import java.util.List;
import java.util.Map;

public class Pagination {

    private static final String FIRST_RESULT = "firstResult";
    private static final String MAX_RESULTS = "maxResults";

    public static Page extractPage() {
        final ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes != null) {
            final HttpServletRequest request = attributes.getRequest();
            final Map<String, String[]> parameters = request.getParameterMap();
            if (!parameters.isEmpty()) {
                final String[] firstResult = parameters.getOrDefault(FIRST_RESULT, null);
                final String[] maxResults = parameters.getOrDefault(MAX_RESULTS, null);
                if (firstResult != null && firstResult.length == 1 && maxResults != null && maxResults.length == 1) {
                    return new Page(Integer.parseInt(firstResult[0]), Integer.parseInt(maxResults[0]));
                }
            }
        }
        return new Page(0, Integer.MAX_VALUE);
    }

    public static <T> List<T> getPage(final List<T> sourceList, final Page page) {
        final Page source = page != null ? page : extractPage();
        final int fromIndex = source.getFirstResult();
        if (sourceList == null || sourceList.size() <= fromIndex){
            return Collections.emptyList();
        }
        return sourceList.subList(fromIndex, Math.min(fromIndex + source.getMaxResults(), sourceList.size()));
    }

}
