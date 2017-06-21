FROM perl:5.24

RUN cpanm -n Test::Deep URI

CMD ["prove", "-lv", "xt"]
