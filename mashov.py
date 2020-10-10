import requests
from requests.exceptions import ConnectionError

class user():
    """Norel Glick's Mashov User class
    User object is used to request data from the Mashov API

    Functions:
        - __init__(username: str, password: str, school: int, year: int) -> Creates the request Session to manipulate with other functions
        - login() -> Sends a login request to the Mashov API using @self.session
        - conversations() -> Gets the users conversations based on the page given (default is 0)
        - grades() -> Gets the users grades one by one as a generator function
        - behaviour() -> Gets the users behaviour one by one as a generator function
    """

    def __init__(self, username: str, password: str, school: int, year: int = 2020):
        """Creates the request Session to manipulate with other functions

        Params:
            - @username: str -> username used to log into Mashov
            - @password: str -> password used to log into Mashov
            - @school: int -> school ID used to log into Mashov
            - @year: int -> english year (20xx) used to log into Mashov (if not specified, default is: 2020)

        Variables:
            - @session: requests.Session -> session used for user
            - @logged_in: boolean -> will become True once user successfully logs in
            - @csrf_token: str -> cookie used to access data after logging in (default: False)
            - @userGUID: str -> user GUID needed to access Mashov API
        """

        self.username = username
        self.password = password
        self.school = school
        self.year = year

        self.session = requests.Session()

        self.logged_in = False
        self.csrf_token = ''
        self.userGUID = ''
        self.user_headers = {'csrf-token': self.csrf_token, 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                                                                   'AppleWebKit/537.36 (KHTML, like Gecko) '
                                                                   'Chrome/79.0.3945.130 Safari/537.36'}

    def login(self):
        """Sends a login request to the Mashov API using @self.session"""

        url = 'https://web.mashov.info/api/login'

        payload = {"username": self.username, "password": self.password, "semel":self.school, "year": self.year}
        headers = {'content-type': 'application/json;chars]et=UTF-8, text/plain', 'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'}

        # send the request while checking for a connection error
        try:
            request = self.session.post(url, json=payload, headers=headers)
        except ConnectionError:
            print("[Mashov] Failed Login: You need an active internet connection to log into Mashov")
            return
        # Check for status errors and print the respective message for each status error. If no error occured login
        try:
            request.raise_for_status()
        except Exception:
            # Check for the status code and print a respecive message
            if request.status_code == 401:
                print("[Mashov] Failed Login: Your username/password/school is probably incorrect. Please check again!")
            elif request.status_code == 403:
                print("[Mashov] Failed Login: Not enough permissions to access the API. Check if you can login through your browser")
            elif request.status_code == 404:
                print("[Mashov] Failed Login: Page not found (404)")
            elif request.status_code == 408:
                print("[Mashov] Failed Login: Request timed out")
            elif request.status_code == 429:
                print("[Mashov] Failed Login: Sending too many requests in a short amount of time")
            else:
                print("[Mashov] Failed Login: unknown error occured")
        else:
            # if no error/exception occured, login
            self.logged_in = True
            self.csrf_token = request.cookies['Csrf-Token']
            self.user_headers['x-csrf-token'] = self.csrf_token
            self.userGUID = request.json()['credential']['userId']

            print(f"[Mashov] logged in successfully as: {self.username}")

    def grades(self, teacherName: str = None, subjectName: str = None, gradeType: str = None, minGrade: int = None) -> dict:
        """Gets the users grades one by one as a generator function

        Function gets the parameters that aren't None and filters through the JSON file Mashov
        returned to us. It loops through the filtered dictionaries and yields them one by one
        """

        # if logged in
        if self.logged_in:
            # get params that aren't none and not self
            filled_params = {key: value for key, value in locals().items() if value is not None}
            filled_params.pop('self')

            # get the grades from the server
            url = f'https://web.mashov.info/api/students/{self.userGUID}/grades'

            grades_json = self.session.get(url, headers=self.user_headers).json()

            # If we have been given atleast one paramater that isn't None, filter
            if filled_params:
                grades_dictionary = filter(
                    lambda x: all([True if (key == 'minGrade' and type(x.get('grade')) == int and x.get('grade') >= value) or (value == x.get(key)) else False for key, value in filled_params.items()]), grades_json)
            else:
                grades_dictionary = grades_json

            for grade in grades_dictionary:
                # @grade is a dictionary with keys that have information about the grade

                yield {"Grade Name": grade.get('gradingEvent'), "Grade": grade.get('grade'),
                       "Subject": grade.get('subjectName'), "Teacher": grade.get('teacherName'),
                       "Date": grade.get('timestamp').split('T')[0], "Time": grade.get('timestamp').split('T')[1],
                       "Type": grade.get('gradeType'), "Range": grade.get('rangeGrade')
                       }
        else:
            print("[Mashov] You are not logged in. Returned empty dictionary")
            return {}


    # create new grades() constructors to filter through grade types
    def behaviour(self, subject: str = None, justified: bool = None) -> dict:
        """Gets the users behaviour one by one as a generator function

        Function gets the parameters that aren't None and filters through the JSON file Mashov
        returned to us. It loops through the filtered dictionaries and yields them one by one
        """

        # if logged in
        if self.logged_in:
            #  get the behaviour json file from mashov
            url = f'https://web.mashov.info/api/students/{self.userGUID}/behave'

            behaviour_json = self.session.get(url, headers=self.user_headers).json()

            # loop through the behaviour json given and filter by the parameters given
            for dic in behaviour_json:
                # check justified param
                if justified is not None:
                    if justified == True and dic.get('justified') == -1:
                        continue
                    elif justified == False and dic.get('justified') >= 0 :
                        continue

                # check subject param
                if subject is not None:
                    if dic.get('subject') != subject:
                        continue

                timestamp = dic.get('timestamp').split('T')
                yield {"Behaviour": dic.get('achvaName'),
                       "Subject": dic.get('subject'),
                       "Reporter": dic.get('reporter'),
                       "Justified": dic.get('justified') > 0,
                       "Justification": dic.get('justification'),
                       "Date": timestamp[0],
                       "Time": timestamp[1]
                       }

    def conversations(self, filter: str = None, page: int = 0):
        """Gets the users conversations based on the page given (default is 0)

        Function gets the parameters that aren't None and returns the entirety of the dataset mashov returns.
        The reason for this is because there is alot of information and it's hard for me (norel) to choose
        what to return to the programmer. So I'll just return it all. If you have a problem, tell me lol
        """
        # if logged in
        if self.logged_in:
            # url needs to be page*20 (every page has 20 messages? I guess)
            if filter is not None:
                # use the filter directly on url
                url = f'https://web.mashov.info/api/mail/search/{filter}/conversations?skip={str(20*page)}'
            else:
                url = f'https://web.mashov.info/api/mail/inbox/conversations?skip={str(20*page)}'
            return self.session.get(url, headers=self.user_headers).json()