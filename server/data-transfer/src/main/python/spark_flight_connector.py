
class SparkFlightConnector(object):

    @staticmethod
    def put(dataframe, host, port, descriptor):
        sc = dataframe._sc
        jconn = sc._jvm.com.sony.SparkFlightConnector()
        jconn.put(dataframe._jdf, host, int(port), descriptor)
