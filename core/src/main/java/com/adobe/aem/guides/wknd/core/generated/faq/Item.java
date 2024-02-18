package com.adobe.aem.guides.wknd.core.generated.faq;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Generated;
import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({
        "question",
        "answer",
        "topFaq",
        "tag"
})
@Generated("jsonschema2pojo")
public class Item {

    @JsonProperty("question")
    private String question;
    @JsonProperty("answer")
    private Answer answer;
    @JsonProperty("topFaq")
    private Boolean topFaq;
    @JsonProperty("tag")
    private List<String> tag;
    @JsonIgnore
    private Map<String, Object> additionalProperties = new LinkedHashMap<String, Object>();

    @JsonProperty("question")
    public String getQuestion() {
        return question;
    }

    @JsonProperty("question")
    public void setQuestion(String question) {
        this.question = question;
    }

    @JsonProperty("answer")
    public Answer getAnswer() {
        return answer;
    }

    @JsonProperty("answer")
    public void setAnswer(Answer answer) {
        this.answer = answer;
    }

    @JsonProperty("topFaq")
    public Boolean getTopFaq() {
        return topFaq;
    }

    @JsonProperty("topFaq")
    public void setTopFaq(Boolean topFaq) {
        this.topFaq = topFaq;
    }

    @JsonProperty("tag")
    public List<String> getTag() {
        return tag;
    }

    @JsonProperty("tag")
    public void setTag(List<String> tag) {
        this.tag = tag;
    }

    @JsonAnyGetter
    public Map<String, Object> getAdditionalProperties() {
        return this.additionalProperties;
    }

    @JsonAnySetter
    public void setAdditionalProperty(String name, Object value) {
        this.additionalProperties.put(name, value);
    }

}