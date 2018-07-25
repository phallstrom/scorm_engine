RSpec.describe ScormEngine::Api::Endpoints::Registrations do
  let(:subject) { scorm_engine_client }

  let(:registration_options) {{
    course_id: "testing-golf-explained",
    registration_id: "testing-golf-explained-registration-1",
    learner: {
      id: "testing-golf-explained-learner-1",
      first_name: "Arnold",
      last_name: "Palmer",
    }
  }}

  before do
    against_real_scorm_engine do
      ensure_course_exists(client: subject, course_id: registration_options[:course_id])
      ensure_registration_exists(registration_options.merge(client: subject))
      ensure_course_exists(client: subject, course_id: registration_options[:course_id] + "-no-registrations")
    end
  end

  describe "#get_registrations" do
    let(:registrations) { subject.get_registrations }

    it "is successful" do
      expect(registrations.success?).to eq true
    end

    it "returns an array of registrations" do
      expect(registrations.result.all? {|r| r.is_a?(ScormEngine::Models::Registration)}).to eq true
    end

    it "includes results we expect" do
      reg = registrations.result.detect { |r| r.id == registration_options[:registration_id] }
      expect(reg).not_to be nil
    end

    describe "filtering by course_id" do
      it "includes results" do
        registrations = subject.get_registrations(course_id: registration_options[:course_id])
        reg = registrations.result.detect { |r| r.id == registration_options[:registration_id] }
        expect(reg).not_to be nil
      end

      it "excludes results" do
        registrations = subject.get_registrations(course_id: registration_options[:course_id] + "-no-registrations")
        reg = registrations.result.detect { |r| r.id == registration_options[:registration_id] }
        expect(reg).to be nil
      end
    end

    describe "filtering by learner_id" do
      it "includes results" do
        registrations = subject.get_registrations(learner_id: registration_options[:learner][:id])
        reg = registrations.result.detect { |r| r.id == registration_options[:registration_id] }
        expect(reg).not_to be nil
      end

      it "excludes results" do
        registrations = subject.get_registrations(learner_id: "some-other-learner-id")
        reg = registrations.result.detect { |r| r.id == registration_options[:registration_id] }
        expect(reg).to be nil
      end
    end
  end

  describe "#get_registration_exists" do
    it "is true when registration exists" do
      response = subject.get_registration_exists(registration_id: registration_options[:registration_id])
      aggregate_failures do
        expect(response.success?).to eq true
        expect(response.result).to eq true
      end
    end

    it "is false when registration does not exist" do
      response = subject.get_registration_exists(registration_id: "reg-does-not-exist")
      aggregate_failures do
        expect(response.result).to eq false
        expect(response.status).to eq 404
      end
    end
  end

  describe "#post_registration" do
    it "is successful" do
      subject.delete_registration(registration_options)
      response = subject.post_registration(registration_options)
      aggregate_failures do
        expect(response.success?).to eq true
        expect(response.status).to eq 204
      end
    end

    it "fails if course_id is invalid" do
      response = subject.post_registration(registration_options.merge(course_id: "invalid-bogus"))
      aggregate_failures do
        expect(response.success?).to eq false
        expect(response.status).to eq 400
        expect(response.message).to match(/External Package ID 'invalid-bogus'/)
      end
    end

    it "fails if registration_id already exists" do
      response = subject.post_registration(registration_options)
      aggregate_failures do
        expect(response.success?).to eq false
        expect(response.status).to eq 400
        expect(response.message).to match(/This RegistrationId is already in use/)
      end
    end
  end
end