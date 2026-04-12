# ==============================================
# 1. Install Packages
# ==============================================
install.packages("readr")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("forecast", dependencies = TRUE)
install.packages("prophet")

# ==============================================
# 2. Load Libraries
# ==============================================
library(readr)
library(dplyr)
library(ggplot2)
library(forecast)
library(prophet)

# ==============================================
# 3. Load Data
# ==============================================
df <- read_csv("C:/Users/LENOVO/Downloads/مؤشرات الأمراض الغير معدية في السعودية.csv")
head(df)
str(df)

# ==============================================
# 4. Data Wrangling (Renaming & Type Conversion)
# ==============================================
df = df %>%
    rename(
        indicator = `GHO (CODE)`,
        year =    `YEAR (CODE)` ,
        age =   `AGEGROUP (CODE)`,
        sex =   `SEX (CODE)`,
        value = Numeric)

df$value = as.numeric(df$value)
summary(df$value)

# ==============================================
# 5. Filter Diabetes Data
# ==============================================
# فلترة بيانات السكري
gluc = df %>%
    filter(indicator == "NCD_GLUC_02")
nrow(gluc)

# تجميع البيانات سنويًا
gluc_yearly = gluc %>%
    group_by(year) %>%
    summarise(rate = mean(value,na.rm =TRUE))

#
ggplot(gluc_yearly,aes(x= year,rate)) + 
    geom_line()+
    ggtitle("Diabetes Trend")

# ==============================================
# 6. Convert to Time Series
# ==============================================

# تحويل البيانات إلى سلسلة زمنية
ts_gluc = ts(gluc_yearly$rate,start = min(gluc_yearly$year), frequency = 1)

# ==============================================
# 7. ARIMA Model
# ==============================================
 # ARIMA بناء نموذج
model_gluc = auto.arima(ts_gluc)
# التنبؤ لمدة 9 سنوات
forecate_gluc = forecast(model_gluc, h= 9)
# رسم التوقع
plot(forecate_gluc)
forecate_gluc


# ==============================================
# 8. Model Evaluation
# ==============================================

# تقسيم البيانات إلى بيانات تدريب وبيانات اختبار 
gluc_train = gluc_yearly%>%
    filter(year <=2005)
gluc_test = gluc_yearly%>%
    filter(year > 2005)

# تقييم دقة النموذج
accuracy(forecate_gluc, gluc_test$rate)
# رسم التوقعات مقابل القيم الحقيقية
plot(forecate_gluc)
lines(ts(gluc_test$rate,start =2006, frequency = 1),col = "red")


# ==============================================
# 9. Prophet Model
# ==============================================

# Prophet تجهيز البيانات لتناسب
df_prophet = gluc_yearly %>%
    rename(
        ds = year,
        y= rate
    )
# تحويل السنة إلى تاريخ
df_prophet$ds = as.Date(paste0(df_prophet$ds, "-01-01"))
# بناء النموذج
model_prophet = prophet(df_prophet,weekly.seasonality = TRUE, n.changepoints = 23, daily.seasonality=TRUE)
# إنشاء بيانات مستقبلية 
future = make_future_dataframe(model_prophet,periods = 9,freq = "year")
# التنبؤ
forecast_prophet = predict(model_prophet,future)
# رسم النتائج
plot(model_prophet,forecast_prophet)


# ==============================================
# 10. Filter Obesity Data
# ==============================================

bmi = df %>%
    filter(indicator == "NCD_BMI_30A")

bmi_yearly = bmi %>%
    group_by(year) %>%
    summarise(rate = mean(value,na.rm =TRUE))

# ==============================================
# 11. Merge Data
# ==============================================
merged_data = merge(gluc_yearly,bmi_yearly, by = "year")
names(merged_data) = c("year", "diabetes", "obesity")

# ==============================================
# 12. Correlation
# ==============================================
cor(merged_data$diabetes, merged_data$obesity)
cor.test(merged_data$diabetes, merged_data$obesity)

# ==============================================
# 13. Visualization of Correlation
# ==============================================
plot(merged_data$obesity,
     merged_data$diabetes, 
     xlab = "Obesity",
     ylab = "Diabetes",
     main = "Relationship between Obesity and Diabetes")
abline(lm(diabetes ~ obesity, data = merged_data ), col = "red")
     