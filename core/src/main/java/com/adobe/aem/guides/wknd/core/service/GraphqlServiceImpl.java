package com.adobe.aem.guides.wknd.core.service;

import com.adobe.aem.guides.wknd.core.generated.faq.FaqResponse;
import com.adobe.aem.guides.wknd.core.generated.faq.Item;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.osgi.service.component.annotations.Component;

import java.util.*;

@Component(service  = GraphqlService.class)
public class GraphqlServiceImpl implements GraphqlService {

    private static final String graphQLEndpoint = "http://localhost:4502/graphql/execute.json/faq/faq-tag-query";


    @Override
    public List<Item> getGrapqhQlData(Optional<String> tagField) {

        String variables = "{\"tag\": \""+ tagField.get()  + "\"}";


        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpPost httpPost = new HttpPost(graphQLEndpoint);

        try {

            BasicCredentialsProvider credentialsProvider = new BasicCredentialsProvider();
            credentialsProvider.setCredentials(AuthScope.ANY, new UsernamePasswordCredentials("admin", "admin"));
            httpClient = HttpClients.custom().setDefaultCredentialsProvider(credentialsProvider).build();

            // Set headers
            httpPost.setHeader("Content-Type", "application/json");

            // Set GraphQL query and variables
            StringEntity requestEntity = new StringEntity(
                    "{\"variables\":" + variables + "}"
            );
            httpPost.setEntity(requestEntity);

            // Execute HTTP post request
            HttpResponse response = httpClient.execute(httpPost);
            HttpEntity responseEntity = response.getEntity();

            // Process response
            if (responseEntity != null) {
                String responseString = EntityUtils.toString(responseEntity);

                // Create an ObjectMapper instance
                ObjectMapper objectMapper = new ObjectMapper();

                // Deserialize JSON into Data object
                FaqResponse faqResponse = objectMapper.readValue(responseString, FaqResponse.class);

                if(faqResponse != null && faqResponse.getData() !=null)
                {
                    List<Item> faqList = faqResponse.getData().getFaqList().getItems();
                    Collections.sort(faqResponse.getData().getFaqList().getItems(), Comparator.comparing(Item::getTopFaq).reversed());
                    return  faqList;
                }

                return new ArrayList<>();
            }
        } catch (Exception e) {
            e.printStackTrace();
            // Handle exception
        } finally {
            try {
                httpClient.close();
            } catch (Exception e) {
                e.printStackTrace();
                // Handle exception
            }
        }
        return new ArrayList<>();
    }
}
