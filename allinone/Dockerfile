FROM registry.cn-qingdao.aliyuncs.com/metersphere/metersphere:v3.x as metersphere
FROM registry.cn-qingdao.aliyuncs.com/metersphere/task-runner:v3.x as task-runner
FROM registry.cn-qingdao.aliyuncs.com/metersphere/result-hub:v3.x as result-hub

FROM registry.cn-qingdao.aliyuncs.com/metersphere/alpine-openjdk21-jre

COPY --from=metersphere /app /metersphere
COPY --from=task-runner /app /task-runner
COPY --from=result-hub  /app /result-hub

COPY --from=task-runner /opt/jmeter /opt/jmeter

ENV AB_OFF=true
ENV MS_VERSION=${MS_VERSION}

ADD start.sh /start.sh
ADD metersphere.sh /metersphere.sh
ADD task-runner.sh /task-runner.sh
ADD result-hub.sh /result-hub.sh

RUN chmod +x /start.sh
ENTRYPOINT ["sh", "/start.sh"]

