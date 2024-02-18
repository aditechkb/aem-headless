package com.adobe.aem.guides.wknd.core.servlet;


import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.sling.api.SlingHttpServletRequest;
import org.apache.sling.api.SlingHttpServletResponse;
import org.apache.sling.api.servlets.HttpConstants;
import org.apache.sling.api.servlets.ServletResolverConstants;
import org.apache.sling.api.servlets.SlingAllMethodsServlet;
import org.apache.sling.servlets.annotations.SlingServletResourceTypes;
import org.osgi.service.component.annotations.Component;

import javax.servlet.Servlet;

@Component(service = Servlet.class, property = {
        ServletResolverConstants.SLING_SERVLET_PATHS + "=/bin/graphql"
})
@SlingServletResourceTypes(
        resourceTypes = "sling/servlet/default",
        methods = HttpConstants.METHOD_POST
)
public class GraphqlServlet extends SlingAllMethodsServlet {

    private final static String graphQuery = "query{\n" +
            "  headlessCfModelList{\n" +
            "    items{\n" +
            "      title\n" +
            "      description {\n" +
            "        json\n" +
            "      }\n" +
            "    }\n" +
            "  }\n" +
            "}";

    @Override
    protected  void doGet(SlingHttpServletRequest request, SlingHttpServletResponse response){

        callGraphqlEndpoint(graphQuery);
    }

    public String callGraphqlEndpoint(String graphqlQuery) {
        // GraphQL endpoint URL
        String endpointUrl = "http://localhost:4502/graphql/execute.json/faq/faq-query";

        try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
            HttpPost httpPost = new HttpPost(endpointUrl);

            // Set GraphQL query in the request body
            StringEntity requestEntity = new StringEntity(graphqlQuery);
            httpPost.setEntity(requestEntity);

            // Set headers
            httpPost.setHeader("Content-Type", "application/json");

            // Execute the request
            HttpResponse response = httpClient.execute(httpPost);
            HttpEntity responseEntity = response.getEntity();

            if (responseEntity != null) {
                // Parse and return the response
                return EntityUtils.toString(responseEntity);
            }
        } catch (Exception e) {
            e.printStackTrace();
            // Handle exception
        }

        return null;
    }

}
