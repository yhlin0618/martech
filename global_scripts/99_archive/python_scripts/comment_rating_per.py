# comment_per.py
import openai

def rate_comment(title, body, propertyname, propertytype, gpt_key, model="gpt-4o-mini"):
    """
    使用 GPT 模型對單筆評論進行評分。

    參數:
      title: 評論標題
      body: 評論內容
      propertyname: 要評分的屬性名稱
      propertytype: 評分類別，例如 "屬性" 或 "品牌個性"
      gpt_key: GPT API 金鑰
      model: 使用的 GPT 模型，預設為 "gpt-4o-mini"

    回傳:
      GPT 回應的評分結果字串，格式預期為 "[分數,理由]"，
      若發生錯誤則回傳錯誤訊息。
    """
    # 建立 OpenAI 客戶端，並指定 API 金鑰
    client = openai.OpenAI(api_key=gpt_key)

    # 構造提示訊息
    message_text = (
        f"Title: {title}\n"
        f"Body: {body}\n"
        f"Evaluate the comment regarding the product's '{propertyname}', which is categorized as a {propertytype} feature.\n"
        f"Use the following rules to respond:\n"
        f"1. If the comment does not demonstrate the stated characteristic in any way, reply exactly [NaN,NaN] without any additional reasoning or explanation.\n"
        f"2. Otherwise, rate your agreement with the statement on a scale from 0 to 10, where:\n"
        f"   10: Strongly Agree\n"
        f"   9: Very Strongly Agree\n"
        f"   8: Strongly Agree\n"
        f"   7: Moderately Agree\n"
        f"   6: Somewhat Agree\n"
        f"   5: Neither Agree nor Disagree\n"
        f"   4: Somewhat Disagree\n"
        f"   3: Moderately Disagree\n"
        f"   2: Disagree\n"
        f"   1: Very Disagree\n"
        f"   0: Strongly Disagree\n"
        f"Provide your rationale in the format: [Score, Reason].\n"
        f"** Please double-check that if the comment does not demonstrate the stated characteristic in any way, your reply is exactly [NaN,NaN] with no extra explanation."
    )

    try:
        # 呼叫新版 API 來產生回應
        completion = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "Forget any previous information."},
                {"role": "user", "content": message_text}
            ]
        )
        # 根據回應結構取得產生的文字
        return completion.choices[0].message.content.strip()
    except Exception as e:
        return f"Error: {e}"