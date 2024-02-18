package com.adobe.aem.guides.wknd.core.service;

import com.adobe.aem.guides.wknd.core.generated.faq.FaqList;
import com.adobe.aem.guides.wknd.core.generated.faq.Item;

import java.util.List;
import java.util.Optional;

public interface GraphqlService {

    public List<Item> getGrapqhQlData(Optional<String> tagField);

}
