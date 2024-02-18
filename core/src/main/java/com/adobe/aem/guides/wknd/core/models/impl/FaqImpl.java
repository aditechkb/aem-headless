package com.adobe.aem.guides.wknd.core.models.impl;

import com.adobe.aem.guides.wknd.core.generated.faq.Item;
import com.adobe.aem.guides.wknd.core.models.Faq;
import com.adobe.aem.guides.wknd.core.service.GraphqlService;
import org.apache.sling.api.SlingHttpServletRequest;
import org.apache.sling.api.resource.Resource;
import org.apache.sling.models.annotations.DefaultInjectionStrategy;
import org.apache.sling.models.annotations.Model;
import org.apache.sling.models.annotations.injectorspecific.OSGiService;
import org.apache.sling.models.annotations.injectorspecific.ValueMapValue;

import java.util.Arrays;
import java.util.List;

@Model(
        adaptables = {SlingHttpServletRequest.class, Resource.class},
        adapters = {Faq.class},
        resourceType = {BylineImpl.RESOURCE_TYPE},
        defaultInjectionStrategy = DefaultInjectionStrategy.OPTIONAL
)
public class FaqImpl implements Faq {

    @OSGiService
    GraphqlService graphqlService;

    @ValueMapValue
    String[] tagfield;

    @Override
    public List<Item> getFaqList() {
        return graphqlService.getGrapqhQlData(Arrays.stream(tagfield).findFirst());
    }



}
