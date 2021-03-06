require 'rails_helper'

describe NamespacePolicy do

  subject { described_class }

  let(:user)        { create(:user) }
  let(:owner)       { create(:user) }
  let(:viewer)      { create(:user) }
  let(:contributor) { create(:user) }
  let(:team) do
    create(:team,
           owners: [owner],
           contributors: [contributor],
           viewers: [viewer])
  end
  let(:namespace) { create(:namespace, registry: @registry, team: team) }

  before :each do
    @admin = create(:admin)
    @registry = create(:registry)
  end

  permissions :pull? do

    it 'allows access to user with viewer role' do
      expect(subject).to permit(viewer, namespace)
    end

    it 'allows access to user with contributor role' do
      expect(subject).to permit(contributor, namespace)
    end

    it 'allows access to user with owner role' do
      expect(subject).to permit(owner, namespace)
    end

    it 'disallows access to user who is not part of the team' do
      expect(subject).to_not permit(user, namespace)
    end

    it 'allows access to any user if the namespace is public' do
      namespace.public = true
      expect(subject).to permit(user, namespace)
    end

    it 'allows access to admin users even if they are not part of the team' do
      expect(subject).to permit(@admin, namespace)
    end

    it 'always allows access to a global namespace' do
      expect(subject).to permit(create(:user), @registry.global_namespace)
    end

  end

  permissions :push? do

    it 'disallow access to user with viewer role' do
      expect(subject).to_not permit(viewer, namespace)
    end

    it 'allows access to user with contributor role' do
      expect(subject).to permit(contributor, namespace)
    end

    it 'allows access to user with owner role' do
      expect(subject).to permit(owner, namespace)
    end

    it 'disallows access to user who is not part of the team' do
      expect(subject).to_not permit(user, namespace)
    end

    context 'global namespace' do
      it 'allows access to administrators' do
        expect(subject).to permit(@admin, @registry.global_namespace)
      end

      it 'denies access to other users' do
        expect(subject).not_to permit(user, @registry.global_namespace)
      end
    end

  end

  permissions :toggle_public? do

    it 'allows admin to change it' do
      expect(subject).to permit(@admin, namespace)
    end

    it 'disallows access to user who is not part of the team' do
      expect(subject).to_not permit(user, namespace)
    end

    it 'disallow access to user with viewer role' do
      expect(subject).to_not permit(viewer, namespace)
    end

    it 'disallow access to user with contributor role' do
      expect(subject).to_not permit(contributor, namespace)
    end

    context 'global namespace' do
      let(:namespace) { create(:namespace, global: true, public: true) }

      it 'disallow access to everybody' do
        expect(subject).to_not permit(@admin, namespace)
      end
    end

  end

  describe 'scope' do

    it 'shows namespaces controlled by teams the user is member of' do
      expected = team.namespaces
      expect(Pundit.policy_scope(viewer, Namespace).to_a).to match_array(expected)

      expect(Pundit.policy_scope(create(:user), Namespace).to_a).to be_empty
    end

    it 'always shows public namespaces' do
      n = create(:namespace, public: true)
      create(:team, namespaces: [n], owners: [owner])
      expect(Pundit.policy_scope(create(:user), Namespace).to_a).to match_array([n])
    end

    it 'never shows public or personal namespaces' do
      user = create(:user)
      expect(Namespace.find_by(name: user.username)).not_to be_nil
      create(:namespace, global: true, public: true)
      expect(Pundit.policy_scope(create(:user), Namespace).to_a).to be_empty
    end

  end

end
